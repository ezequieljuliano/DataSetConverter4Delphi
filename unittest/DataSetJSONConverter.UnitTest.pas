unit DataSetJSONConverter.UnitTest;

interface

uses
  TestFramework,
  System.Classes,
  System.SysUtils,
  System.JSON,
  Datasnap.DBClient,
  DataSetJSONConverter4D,
  Data.DB;

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

    procedure TestConvertJSONToDataSetOwnsObject();
  end;

implementation

{ TTestsDataSetJSONConverter }

procedure TTestsDataSetJSONConverter.SetUp;
begin
  inherited;
  FCdsSales := TClientDataSet.Create(nil);
  NewDataSetField(FCdsSales, ftInteger, 'Id');
  NewDataSetField(FCdsSales, ftString, 'Description', 100);
  NewDataSetField(FCdsSales, ftDate, 'Date');
  NewDataSetField(FCdsSales, ftTime, 'Time');
  NewDataSetField(FCdsSales, ftDataSet, 'Customers', 0, 'JSONObject');
  NewDataSetField(FCdsSales, ftDataSet, 'Products', 0, 'JSONArray');

  FCdsCustomers := TClientDataSet.Create(nil);
  NewDataSetField(FCdsCustomers, ftInteger, 'Id');
  NewDataSetField(FCdsCustomers, ftString, 'Name', 100);
  NewDataSetField(FCdsCustomers, ftDateTime, 'Birth');
  FCdsCustomers.DataSetField := TDataSetField(FCdsSales.FieldByName('Customers'));

  FCdsProducts := TClientDataSet.Create(nil);
  NewDataSetField(FCdsProducts, ftInteger, 'Id');
  NewDataSetField(FCdsProducts, ftString, 'Description', 100);
  NewDataSetField(FCdsProducts, ftFloat, 'Value');
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
  cJSONArray =
    '[{"Id":1,"Name":"Customers 1","Birth":"2014-01-22 14:05:03"},' +
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}]';
  cJSONObject =
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}';
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

  vJSONArray := Converter.DataSet(FCdsCustomers).AsJSONArray;
  CheckEqualsString(cJSONArray, vJSONArray.ToString);

  vJSONObject := Converter.DataSet.Source(FCdsCustomers).AsJSONObject;
  CheckEqualsString(cJSONObject, vJSONObject.ToString);

  FreeAndNil(vJSONArray);
  FreeAndNil(vJSONObject);
end;

procedure TTestsDataSetJSONConverter.TestConvertDataSetToJSONComplex;
const
  cJSON =
    '{"Id":1,"Description":"Sales 1","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":1,"Description":"Product 1","Value":100},' +
    '{"Id":2,"Description":"Product 2","Value":200}]}';
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

  vJSONObject := Converter.DataSet(FCdsSales).AsJSONObject;
  CheckEqualsString(cJSON, vJSONObject.ToString);

  FreeAndNil(vJSONObject);
end;

procedure TTestsDataSetJSONConverter.TestConvertJSONToDataSetBasic;
const
  cJSONArray =
    '[{"Id":1,"Name":"Customers 1","Birth":"2014-01-22 14:05:03"},' +
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}]';
  cJSONObject =
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}';
var
  vJSONArray: TJSONArray;
  vJSONObject: TJSONObject;
begin
  FCdsCustomers.DataSetField := nil;
  FCdsCustomers.CreateDataSet;

  vJSONArray := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(cJSONArray), 0) as TJSONArray;
  vJSONObject := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(cJSONObject), 0) as TJSONObject;

  Converter.JSON(vJSONObject).ToDataSet(FCdsCustomers);
  CheckFalse(FCdsCustomers.IsEmpty);

  FCdsCustomers.EmptyDataSet;

  Converter.JSON.Source(vJSONArray).ToDataSet(FCdsCustomers);
  CheckFalse(FCdsCustomers.IsEmpty);

  FreeAndNil(vJSONArray);
  FreeAndNil(vJSONObject);
end;

procedure TTestsDataSetJSONConverter.TestConvertJSONToDataSetComplex;
const
  cJSON =
    '{"Id":1,"Description":"Sales 1","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":1,"Description":"Product 1","Value":100},' +
    '{"Id":2,"Description":"Product 2","Value":200}]}';
var
  vJSONObject: TJSONObject;
begin
  vJSONObject := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(cJSON), 0) as TJSONObject;

  Converter.JSON(vJSONObject).ToDataSet(FCdsSales);

  CheckFalse(FCdsSales.IsEmpty);
  CheckFalse(FCdsCustomers.IsEmpty);
  CheckFalse(FCdsProducts.IsEmpty);

  FreeAndNil(vJSONObject);
end;

procedure TTestsDataSetJSONConverter.TestConvertJSONToDataSetOwnsObject;
const
  cJSONArray =
    '[{"Id":1,"Name":"Customers 1","Birth":"2014-01-22 14:05:03"},' +
    '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}]';
var
  vJSONArray: TJSONArray;
begin
  FCdsCustomers.DataSetField := nil;
  FCdsCustomers.CreateDataSet;

  vJSONArray := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(cJSONArray), 0) as TJSONArray;

  Converter.JSON.Source(vJSONArray, True).ToDataSet(FCdsCustomers);
  CheckFalse(FCdsCustomers.IsEmpty);
end;

initialization

RegisterTest(TTestsDataSetJSONConverter.Suite);

end.
