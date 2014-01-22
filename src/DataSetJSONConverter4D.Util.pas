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

unit DataSetJSONConverter4D.Util;

interface

uses
  DB,
  SysUtils,
  System.DateUtils;

type

  TDataSetFieldType = (dsfUnknown, dsfJSONObject, dsfJSONArray);

const

  _cDescDataSetFieldType: array [TDataSetFieldType] of string = ('Unknown', 'JSONObject', 'JSONArray');

type

  TDataSetJSONConverterUtil = class
  public
    class function GetDataSetFieldType(const pDataSetField: TDataSetField): TDataSetFieldType; static;

    class function NewField(const pDataSet: TDataSet; const pFieldType: TFieldType; const pFieldName: string; pSize: Integer = 0;
      const pOrigin: string = ''): TField; static;

    class function ISODateTimeToString(const pDateTime: TDateTime): string; static;
    class function ISODateToString(const pDate: TDateTime): string; static;
    class function ISOTimeToString(const pTime: TTime): string; static;

    class function ISOStrToDateTime(const pDateTimeAsString: string): TDateTime; static;
    class function ISOStrToDate(const pDateAsString: string): TDate; static;
    class function ISOStrToTime(const pTimeAsString: string): TTime; static;
  end;

implementation

{ TDataSetJSONConverterUtil }

class function TDataSetJSONConverterUtil.GetDataSetFieldType(const pDataSetField: TDataSetField): TDataSetFieldType;
var
  vIndice: Integer;
  vOrigin: string;
begin
  Result := dsfUnknown;

  vOrigin := Trim(pDataSetField.Origin);

  for vIndice := Ord(Low(TDataSetFieldType)) to Ord(High(TDataSetFieldType)) do
    if (LowerCase(_cDescDataSetFieldType[TDataSetFieldType(vIndice)]) = LowerCase(vOrigin)) then
      Exit(TDataSetFieldType(vIndice));
end;

class function TDataSetJSONConverterUtil.ISODateTimeToString(const pDateTime: TDateTime): string;
var
  vFS: TFormatSettings;
begin
  vFS.TimeSeparator := ':';
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', pDateTime, vFS);
end;

class function TDataSetJSONConverterUtil.ISODateToString(const pDate: TDateTime): string;
begin
  Result := FormatDateTime('YYYY-MM-DD', pDate);
end;

class function TDataSetJSONConverterUtil.ISOStrToDate(const pDateAsString: string): TDate;
begin
  Result := EncodeDate(StrToInt(Copy(pDateAsString, 1, 4)), StrToInt(Copy(pDateAsString, 6, 2)), StrToInt(Copy(pDateAsString, 9, 2)));
end;

class function TDataSetJSONConverterUtil.ISOStrToDateTime(const pDateTimeAsString: string): TDateTime;
begin
  Result := EncodeDateTime(StrToInt(Copy(pDateTimeAsString, 1, 4)), StrToInt(Copy(pDateTimeAsString, 6, 2)), StrToInt(Copy(pDateTimeAsString, 9, 2)),
    StrToInt(Copy(pDateTimeAsString, 12, 2)), StrToInt(Copy(pDateTimeAsString, 15, 2)), StrToInt(Copy(pDateTimeAsString, 18, 2)), 0);
end;

class function TDataSetJSONConverterUtil.ISOStrToTime(const pTimeAsString: string): TTime;
begin
  Result := EncodeTime(StrToInt(Copy(pTimeAsString, 1, 2)), StrToInt(Copy(pTimeAsString, 4, 2)), StrToInt(Copy(pTimeAsString, 7, 2)), 0);
end;

class function TDataSetJSONConverterUtil.ISOTimeToString(const pTime: TTime): string;
var
  vFS: TFormatSettings;
begin
  vFS.TimeSeparator := ':';
  Result := FormatDateTime('hh:nn:ss', pTime, vFS);
end;

class function TDataSetJSONConverterUtil.NewField(const pDataSet: TDataSet; const pFieldType: TFieldType; const pFieldName: string; pSize: Integer;
  const pOrigin: string): TField;
begin
  Result := DefaultFieldClasses[pFieldType].Create(pDataSet);
  Result.FieldName := pFieldName;

  if Result.FieldName = '' then
    Result.FieldName := 'Field' + IntToStr(pDataSet.FieldCount + 1);

  Result.FieldKind := fkData;
  Result.DataSet := pDataSet;
  Result.Name := pDataSet.Name + Result.FieldName;
  Result.Size := pSize;
  Result.Origin := pOrigin;

  if (pFieldType = ftString) and (pSize <= 0) then
    raise Exception.CreateFmt('Size not defined "%s".', [pFieldName]);
end;

end.
