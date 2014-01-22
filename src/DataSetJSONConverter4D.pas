(*
  Copyright 2014 Ezequiel Juliano Müller - ezequieljuliano@gmail.com

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*)

unit DataSetJSONConverter4D;

interface

uses
  System.SysUtils,
  Data.DBXJSON,
  Data.SqlTimSt,
  Data.FmtBcd,
  DB,
  DBClient,
  DataSetJSONConverter4D.Util;

type

  EDataSetJSONConverterException = class(Exception);

  TDataSetJSONConverter = class
  strict private
    class function AsJSONArray(const pDataSet: TDataSet): TJSONArray;
    class function AsJSONObject(const pDataSet: TDataSet): TJSONObject;
  public
    class procedure UnMarshalToJSON(const pDataSet: TDataSet; out pJSON: TJSONArray); overload; static;
    class procedure UnMarshalToJSON(const pDataSet: TDataSet; out pJSON: TJSONObject); overload; static;
  end;

  TJSONDataSetConverter = class
  strict private
    class procedure ToDataSet(const pJSON: TJSONArray; pDataSet: TDataSet); overload;
    class procedure ToDataSet(const pJSON: TJSONObject; pDataSet: TDataSet); overload;
  public
    class procedure UnMarshalToDataSet(const pJSON: TJSONObject; pDataSet: TDataSet); overload; static;
    class procedure UnMarshalToDataSet(const pJSON: TJSONArray; pDataSet: TDataSet); overload; static;
  end;

implementation

{ TDataSetConverter }

class function TDataSetJSONConverter.AsJSONArray(const pDataSet: TDataSet): TJSONArray;
var
  vBookMark: TBookmark;
begin
  Result := nil;
  if not pDataSet.IsEmpty then
  begin
    try
      Result := TJSONArray.Create;

      vBookMark := pDataSet.Bookmark;

      pDataSet.First;
      while not pDataSet.Eof do
      begin
        Result.AddElement(AsJSONObject(pDataSet));
        pDataSet.Next;
      end;

    finally
      if pDataSet.BookmarkValid(vBookMark) then
        pDataSet.GotoBookmark(vBookMark);

      pDataSet.FreeBookmark(vBookMark);
    end;
  end;
end;

class function TDataSetJSONConverter.AsJSONObject(const pDataSet: TDataSet): TJSONObject;
var
  vI: Integer;
  vKey: string;
  vTs: TSQLTimeStamp;
  vNestedDataSet: TDataSet;
  vTypeDataSetField: TDataSetFieldType;
begin
  Result := nil;
  if not pDataSet.IsEmpty then
  begin
    Result := TJSONObject.Create;
    for vI := 0 to Pred(pDataSet.FieldCount) do
    begin
      vKey := pDataSet.Fields[vI].FieldName;
      case pDataSet.Fields[vI].DataType of
        TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint:
          Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[vI].AsInteger));
        TFieldType.ftLargeint:
          begin
            Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[vI].AsLargeInt));
          end;
        TFieldType.ftSingle, TFieldType.ftFloat:
          Result.AddPair(vKey, TJSONNumber.Create(pDataSet.Fields[vI].AsFloat));
        ftString, ftWideString, ftMemo:
          Result.AddPair(vKey, pDataSet.Fields[vI].AsWideString);
        TFieldType.ftDate:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, TDataSetJSONConverterUtil.ISODateToString(pDataSet.Fields[vI].AsDateTime));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftDateTime:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, TDataSetJSONConverterUtil.ISODateTimeToString(pDataSet.Fields[vI].AsDateTime));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftTimeStamp, TFieldType.ftTime:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              vTs := pDataSet.Fields[vI].AsSQLTimeStamp;
              Result.AddPair(vKey, SQLTimeStampToStr('hh:nn:ss', vTs));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftCurrency:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, FormatCurr('0.00##', pDataSet.Fields[vI].AsCurrency));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftFMTBcd:
          begin
            if not pDataSet.Fields[vI].IsNull then
            begin
              Result.AddPair(vKey, TJSONNumber.Create(BcdToDouble(pDataSet.Fields[vI].AsBcd)));
            end
            else
              Result.AddPair(vKey, TJSONNull.Create);
          end;
        TFieldType.ftDataSet:
          begin
            vTypeDataSetField := TDataSetJSONConverterUtil.GetDataSetFieldType(TDataSetField(pDataSet.Fields[vI]));

            vNestedDataSet := TDataSetField(pDataSet.Fields[vI]).NestedDataSet;

            case vTypeDataSetField of
              dsfJSONObject:
                Result.AddPair(vKey, AsJSONObject(vNestedDataSet));
              dsfJSONArray:
                Result.AddPair(vKey, AsJSONArray(vNestedDataSet));
            end;
          end
      else
        raise EDataSetJSONConverterException.Create('Cannot find type for field ' + vKey);
      end;
    end;
  end;
end;

class procedure TDataSetJSONConverter.UnMarshalToJSON(const pDataSet: TDataSet; out pJSON: TJSONArray);
begin
  pJSON := AsJSONArray(pDataSet);
end;

class procedure TDataSetJSONConverter.UnMarshalToJSON(const pDataSet: TDataSet; out pJSON: TJSONObject);
begin
  pJSON := AsJSONObject(pDataSet);
end;

{ TJSONConverter }

class procedure TJSONDataSetConverter.ToDataSet(const pJSON: TJSONArray; pDataSet: TDataSet);
var
  vJv: TJSONValue;
begin
  if (pJSON <> nil) and (pDataSet <> nil) then
  begin
    for vJv in pJSON do
      if (vJv is TJSONArray) then
        ToDataSet(vJv as TJSONArray, pDataSet)
      else
        ToDataSet(vJv as TJSONObject, pDataSet)
  end;
end;

class procedure TJSONDataSetConverter.ToDataSet(const pJSON: TJSONObject; pDataSet: TDataSet);
var
  vField: TField;
  vJv: TJSONValue;
  vTypeDataSet: TDataSetFieldType;
  vNestedDataSet: TDataSet;
begin
  if (pJSON <> nil) and (pDataSet <> nil) then
  begin
    vJv := nil;

    pDataSet.Append;

    for vField in pDataSet.Fields do
    begin
      if Assigned(pJSON.Get(vField.FieldName)) then
        vJv := pJSON.Get(vField.FieldName).JsonValue
      else
        Continue;

      case vField.DataType of
        TFieldType.ftInteger, TFieldType.ftSmallint, TFieldType.ftShortint:
          begin
            vField.AsInteger := StrToIntDef(vJv.Value, 0);
          end;
        TFieldType.ftLargeint:
          begin
            vField.AsLargeInt := StrToInt64Def(vJv.Value, 0);
          end;
        TFieldType.ftSingle, TFieldType.ftFloat, TFieldType.ftCurrency, TFieldType.ftFMTBcd:
          begin
            vField.AsFloat := (vJv as TJSONNumber).AsDouble;
          end;
        ftString, ftWideString, ftMemo:
          begin
            vField.AsString := vJv.Value;
          end;
        TFieldType.ftDate:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := TDataSetJSONConverterUtil.ISOStrToDate(vJv.Value);
          end;
        TFieldType.ftDateTime:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := TDataSetJSONConverterUtil.ISOStrToDateTime(vJv.Value);
          end;
        TFieldType.ftTimeStamp, TFieldType.ftTime:
          begin
            if vJv is TJSONNull then
              vField.Clear
            else
              vField.AsDateTime := TDataSetJSONConverterUtil.ISOStrToTime(vJv.Value);
          end;
        TFieldType.ftDataSet:
          begin
            vTypeDataSet := TDataSetJSONConverterUtil.GetDataSetFieldType(TDataSetField(vField));

            vNestedDataSet := TDataSetField(vField).NestedDataSet;

            case vTypeDataSet of
              dsfJSONObject:
                ToDataSet(vJv as TJSONObject, vNestedDataSet);
              dsfJSONArray:
                ToDataSet(vJv as TJSONArray, vNestedDataSet);
            end;
          end
      else
        raise EDataSetJSONConverterException.Create('Cannot find type for field ' + vField.FieldName);
      end;
    end;

    pDataSet.Post;
  end;
end;

class procedure TJSONDataSetConverter.UnMarshalToDataSet(const pJSON: TJSONObject; pDataSet: TDataSet);
begin
  ToDataSet(pJSON, pDataSet);
end;

class procedure TJSONDataSetConverter.UnMarshalToDataSet(const pJSON: TJSONArray; pDataSet: TDataSet);
begin
  ToDataSet(pJSON, pDataSet);
end;

end.
