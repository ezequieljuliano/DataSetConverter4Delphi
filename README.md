DataSet JSON Converter For Delphi
=================================

The DataSetJSONConverter4D it is an API to convert JSON objects for DataSet's and also doing  reverse process, ie, converting DataSet's in JSON.

Works with the TDataSet, and TJSONObject TJSONArray classes.

To use this API you must add the "DataSetJSONConverter4D\src" Path in your Delphi or on your project.

Convert DataSet to JSON
========================

First you must have your DataSet and its Fields created.

    uses DataSetJSONConverter4D;    

    var
      vJSONArray: TJSONArray;
      vJSONObject: TJSONObject;
    begin
      FCdsCustomers.CreateDataSet;
    
      FCdsCustomers.Append;
      FCdsCustomers.FieldByName('Id').AsInteger := 1;
      FCdsCustomers.FieldByName('Name').AsString := 'Customers 1';
      FCdsCustomers.FieldByName('Birth').AsDateTime := 
         StrToDateTime('22/01/2014 14:05:03');
      FCdsCustomers.Post;
    
      FCdsCustomers.Append;
      FCdsCustomers.FieldByName('Id').AsInteger := 2;
      FCdsCustomers.FieldByName('Name').AsString := 'Customers 2';
      FCdsCustomers.FieldByName('Birth').AsDateTime := 
         StrToDateTime('22/01/2014 14:05:03');
      FCdsCustomers.Post;
    
      //Convert All Records
      vJSONArray := Converter.DataSet(FCdsCustomers).AsJSONArray;
 
      //Convert Current Record    
      vJSONObject := Converter.DataSet.Source(FCdsCustomers).AsJSONObject;
    end;
    
Convert JSON to DataSet
=======================

First you must have your DataSet and its Fields created.
    
    uses DataSetJSONConverter4D; 
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
      FCdsCustomers.CreateDataSet;
    
      vJSONArray := 
         TJSONObject
         .ParseJSONValue(TEncoding.ASCII.GetBytes(cJSONArray), 0) as TJSONArray;
      
      vJSONObject := 
         TJSONObject
         .ParseJSONValue(TEncoding.ASCII.GetBytes(cJSONObject), 0) as TJSONObject;
    
      //Convert one record      
      Converter.JSON(vJSONObject).ToDataSet(FCdsCustomers);     
    
      //Convert several records
      Converter.JSON.Source(vJSONArray).ToDataSet(FCdsCustomers);       
    end;

Using DataSetJSONConverter4D
============================

Using this library will is very simple, you simply add the Search Path of your IDE or your project the following directories:

- DataSetJSONConverter4Delphi\src\

Analyze the unit tests they will assist you.