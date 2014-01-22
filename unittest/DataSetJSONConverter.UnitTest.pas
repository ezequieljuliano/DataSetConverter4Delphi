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

unit DataSetJSONConverter.UnitTest;

interface

uses
  TestFramework,
  System.Classes,
  System.SysUtils,
  Datasnap.DBClient,
  DataSetJSONConverter4D.Util,
  DataSetJSONConverter4D,
  Data.DB, Data.DBXJSON;

type

  TTestsDataSetJSONConverter = class(TTestCase)
  strict private
    FCdsCustomers: TClientDataSet;
    FCdsSales: TClientDataSet;
    FCdsProducts: TClientDataSet;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestConvertDataSetToJSONBasic();
    procedure TestConvertDataSetToJSONComplex();

    procedure TestConvertJSONToDataSetBasic();
    procedure TestConvertJSONToDataSetComplex();
  end;

implementation

{ TTestsDataSetJSONConverter }

procedure TTestsDataSetJSONConverter.SetUp;
begin
  inherited;
  FCdsSales := TClientDataSet.Create(nil);
  TDataSetJSONConverterUtil.NewField(FCdsSales, ftInteger, 'Id');
  TDataSetJSONConverterUtil.NewField(FCdsSales, ftString, 'Description', 100);
  TDataSetJSONConverterUtil.NewField(FCdsSales, ftDate, 'Date');
  TDataSetJSONConverterUtil.NewField(FCdsSales, ftTime, 'Time');
  TDataSetJSONConverterUtil.NewField(FCdsSales, ftDataSet, 'Customers', 0, 'JSONObject');
  TDataSetJSONConverterUtil.NewField(FCdsSales, ftDataSet, 'Products', 0, 'JSONArray');

  FCdsCustomers := TClientDataSet.Create(nil);
  TDataSetJSONConverterUtil.NewField(FCdsCustomers, ftInteger, 'Id');
  TDataSetJSONConverterUtil.NewField(FCdsCustomers, ftString, 'Name', 100);
  TDataSetJSONConverterUtil.NewField(FCdsCustomers, ftDateTime, 'Birth');
  FCdsCustomers.DataSetField := TDataSetField(FCdsSales.FieldByName('Customers'));

  FCdsProducts := TClientDataSet.Create(nil);
  TDataSetJSONConverterUtil.NewField(FCdsProducts, ftInteger, 'Id');
  TDataSetJSONConverterUtil.NewField(FCdsProducts, ftString, 'Description', 100);
  TDataSetJSONConverterUtil.NewField(FCdsProducts, ftFloat, 'Value');
  FCdsProducts.DataSetField := TDataSetField(FCdsSales.FieldByName('Products'));

  FCdsSales.CreateDataSet;
end;

procedure TTestsDataSetJSONConverter.TearDown;
begin
  inherited;
  FreeAndNil(FCdsProducts);
  FreeAndNil(FCdsSales);
  FreeAndNil(FCdsCustomers);
end;

procedure TTestsDataSetJSONConverter.TestConvertDataSetToJSONBasic;
const
  cJSONArray = '[{"Id":1,"Name":"Customers 1","Birth":"2014-01-22 14:05:03"},{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}]';
  cJSONObject = '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}';
var
  vJSONArray: TJSONArray;
  vJSONObject: TJSONObject;
begin
  FCdsCustomers.DataSetField := nil;
  FCdsCustomers.CreateDataSet;

  FCdsCustomers.Append;
  FCdsCustomers.FieldByName('Id').AsInteger := 1;
  FCdsCustomers.FieldByName('Name').AsString := 'Customers 1';
  FCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
  FCdsCustomers.Post;

  FCdsCustomers.Append;
  FCdsCustomers.FieldByName('Id').AsInteger := 2;
  FCdsCustomers.FieldByName('Name').AsString := 'Customers 2';
  FCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
  FCdsCustomers.Post;

  TDataSetJSONConverter.UnMarshalToJSON(FCdsCustomers, vJSONArray);
  CheckEqualsString(cJSONArray, vJSONArray.ToString);

  FCdsCustomers.Last;
  TDataSetJSONConverter.UnMarshalToJSON(FCdsCustomers, vJSONObject);
  CheckEqualsString(cJSONObject, vJSONObject.ToString);

  FreeAndNil(vJSONArray);
  FreeAndNil(vJSONObject);
end;

procedure TTestsDataSetJSONConverter.TestConvertDataSetToJSONComplex;
const
  cJSON = '{"Id":1,"Description":"Sales 1","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":1,"Description":"Product 1","Value":100},{"Id":2,"Description":"Product 2","Value":200}]}';
var
  vJSONObject: TJSONObject;
begin
  FCdsSales.Append;
  FCdsSales.FieldByName('Id').AsInteger := 1;
  FCdsSales.FieldByName('Description').AsString := 'Sales 1';
  FCdsSales.FieldByName('Date').AsDateTime := StrToDate('22/01/2014');
  FCdsSales.FieldByName('Time').AsDateTime := StrToTime('14:03:03');

  FCdsCustomers.Append;
  FCdsCustomers.FieldByName('Id').AsInteger := 2;
  FCdsCustomers.FieldByName('Name').AsString := 'Customers 2';
  FCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
  FCdsCustomers.Post;

  FCdsProducts.Append;
  FCdsProducts.FieldByName('Id').AsInteger := 1;
  FCdsProducts.FieldByName('Description').AsString := 'Product 1';
  FCdsProducts.FieldByName('Value').AsFloat := 100;
  FCdsProducts.Post;

  FCdsProducts.Append;
  FCdsProducts.FieldByName('Id').AsInteger := 2;
  FCdsProducts.FieldByName('Description').AsString := 'Product 2';
  FCdsProducts.FieldByName('Value').AsFloat := 200;
  FCdsProducts.Post;

  FCdsSales.Post;

  TDataSetJSONConverter.UnMarshalToJSON(FCdsSales, vJSONObject);
  CheckEqualsString(cJSON, vJSONObject.ToString);

  FreeAndNil(vJSONObject);
end;

procedure TTestsDataSetJSONConverter.TestConvertJSONToDataSetBasic;
const
  cJSONArray = '[{"Id":1,"Name":"Customers 1","Birth":"2014-01-22 14:05:03"},{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}]';
  cJSONObject = '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}';
var
  vJSONArray: TJSONArray;
  vJSONObject: TJSONObject;
begin
  FCdsCustomers.DataSetField := nil;
  FCdsCustomers.CreateDataSet;

  vJSONArray := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(cJSONArray), 0) as TJSONArray;
  vJSONObject := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(cJSONObject), 0) as TJSONObject;

  TJSONDataSetConverter.UnMarshalToDataSet(vJSONObject, FCdsCustomers);
  CheckFalse(FCdsCustomers.IsEmpty);

  FCdsCustomers.EmptyDataSet;
  TJSONDataSetConverter.UnMarshalToDataSet(vJSONArray, FCdsCustomers);
  CheckFalse(FCdsCustomers.IsEmpty);

  FreeAndNil(vJSONArray);
  FreeAndNil(vJSONObject);
end;

procedure TTestsDataSetJSONConverter.TestConvertJSONToDataSetComplex;
const
  cJSON = '{"Id":1,"Description":"Sales 1","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":1,"Description":"Product 1","Value":100},{"Id":2,"Description":"Product 2","Value":200}]}';
var
  vJSONObject: TJSONObject;
begin
  vJSONObject := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(cJSON), 0) as TJSONObject;

  TJSONDataSetConverter.UnMarshalToDataSet(vJSONObject, FCdsSales);

  CheckFalse(FCdsSales.IsEmpty);
  CheckFalse(FCdsCustomers.IsEmpty);
  CheckFalse(FCdsProducts.IsEmpty);

  FreeAndNil(vJSONObject);
end;

initialization

RegisterTest(TTestsDataSetJSONConverter.Suite);

end.
