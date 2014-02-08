# DataSet JSON Converter For Delphi #

The DataSetJSONConverter4D it is an API to convert JSON objects for DataSet's and also doing  reverse process, ie, converting DataSet's in JSON.

Works with the TDataSet, and TJSONObject TJSONArray classes.

To use this library you must add the "DataSetJSONConverter4D\src" Path in your Delphi or on your project.

The DataSetJSONConverter4D API was developed and tested in Delphi XE5.

## Converting DataSet to JSON ##

    procedure ConvertDataSetToJSONBasic;
    const
      cJSONArray = '[{"Id":1,"Name":"Customers 1","Birth":"2014-01-22 14:05:03"},{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}]';
      cJSONObject = '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}';
    var
      vJSONArray: TJSONArray;
      vJSONObject: TJSONObject;
    begin
      CdsCustomers.Append;
      CdsCustomers.FieldByName('Id').AsInteger := 1;
      CdsCustomers.FieldByName('Name').AsString := 'Customers 1';
      CdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
      CdsCustomers.Post;
    
      CdsCustomers.Append;
      CdsCustomers.FieldByName('Id').AsInteger := 2;
      CdsCustomers.FieldByName('Name').AsString := 'Customers 2';
      CdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
      CdsCustomers.Post;
    
      //Convert All Records
      TDataSetJSONConverter.UnMarshalToJSON(CdsCustomers, vJSONArray);
      //Convert Current Record
      TDataSetJSONConverter.UnMarshalToJSON(CdsCustomers, vJSONObject);
    
      FreeAndNil(vJSONArray);
      FreeAndNil(vJSONObject);
    end;

    procedure ConvertDataSetToJSONComplex;
    const
      cJSON = '{"Id":1,"Description":"Sales 1","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":1,"Description":"Product 1","Value":100},{"Id":2,"Description":"Product 2","Value":200}]}';
    var
      vJSONObject: TJSONObject;
    begin
      CdsSales.Append;
      CdsSales.FieldByName('Id').AsInteger := 1;
      CdsSales.FieldByName('Description').AsString := 'Sales 1';
      CdsSales.FieldByName('Date').AsDateTime := StrToDate('22/01/2014');
      CdsSales.FieldByName('Time').AsDateTime := StrToTime('14:03:03');
    
      CdsCustomers.Append;
      CdsCustomers.FieldByName('Id').AsInteger := 2;
      CdsCustomers.FieldByName('Name').AsString := 'Customers 2';
      CdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
      CdsCustomers.Post;
    
      CdsProducts.Append;
      CdsProducts.FieldByName('Id').AsInteger := 1;
      CdsProducts.FieldByName('Description').AsString := 'Product 1';
      CdsProducts.FieldByName('Value').AsFloat := 100;
      CdsProducts.Post;
    
      CdsProducts.Append;
      CdsProducts.FieldByName('Id').AsInteger := 2;
      CdsProducts.FieldByName('Description').AsString := 'Product 2';
      CdsProducts.FieldByName('Value').AsFloat := 200;
      CdsProducts.Post;
    
      CdsSales.Post;
    
      TDataSetJSONConverter.UnMarshalToJSON(FCdsSales, vJSONObject);
    
      FreeAndNil(vJSONObject);
    end;
    
## Converting JSON to DataSet ##
    
    procedure ConvertJSONToDataSetBasic;
    const
      cJSONArray = '[{"Id":1,"Name":"Customers 1","Birth":"2014-01-22 14:05:03"},{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}]';
      cJSONObject = '{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"}';
    var
      vJSONArray: TJSONArray;
      vJSONObject: TJSONObject;
    begin
      vJSONArray := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(cJSONArray), 0) as TJSONArray;
      vJSONObject := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(cJSONObject), 0) as TJSONObject;
    
      //Convert one record
      TJSONDataSetConverter.UnMarshalToDataSet(vJSONObject, CdsCustomers);
      //Convert several records
      TJSONDataSetConverter.UnMarshalToDataSet(vJSONArray, CdsCustomers);
    
      FreeAndNil(vJSONArray);
      FreeAndNil(vJSONObject);
    end;
    
    procedure ConvertJSONToDataSetComplex;
    const
      cJSON = '{"Id":1,"Description":"Sales 1","Date":"2014-01-22","Time":"14:03:03",' +
    '"Customers":{"Id":2,"Name":"Customers 2","Birth":"2014-01-22 14:05:03"},' +
    '"Products":[{"Id":1,"Description":"Product 1","Value":100},{"Id":2,"Description":"Product 2","Value":200}]}';
    var
      vJSONObject: TJSONObject;
    begin
      vJSONObject := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(cJSON), 0) as TJSONObject;
    
      TJSONDataSetConverter.UnMarshalToDataSet(vJSONObject, CdsSales);
    
      FreeAndNil(vJSONObject);
    end;

# Using DataSetJSONConverter4D  #

Using this library will is very simple, you simply add the Search Path of your IDE or your project the following directories:

- DataSetJSONConverter4Delphi\src\

Analyze the unit tests they will assist you.