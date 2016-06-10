DataSet Converter For Delphi
=================================

The DataSetConverter4D it is an API to convert JSON objects for DataSet's and also doing  reverse process, ie, converting DataSet's in JSON.

Works with the TDataSet, and TJSONObject TJSONArray classes.

To use this API you must add the "DataSetConverter4D\src" Path in your Delphi or on your project.

Convert DataSet to JSON
========================

First you must have your DataSet and its Fields created.

    uses 
      DataSetConverter4D, 
      DataSetConverter4D.Impl;    

	var
	  ja: TJSONArray;
	  jo: TJSONObject;
	begin
	  fCdsCustomers.DataSetField := nil;
	  fCdsCustomers.CreateDataSet;
	
	  fCdsCustomers.Append;
	  fCdsCustomers.FieldByName('Id').AsInteger := 1;
	  fCdsCustomers.FieldByName('Name').AsString := 'Customers 1';
	  fCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
	  fCdsCustomers.Post;
	
	  fCdsCustomers.Append;
	  fCdsCustomers.FieldByName('Id').AsInteger := 2;
	  fCdsCustomers.FieldByName('Name').AsString := 'Customers 2';
	  fCdsCustomers.FieldByName('Birth').AsDateTime := StrToDateTime('22/01/2014 14:05:03');
	  fCdsCustomers.Post;

      //Convert all records	
	  ja := TConverter.New.DataSet(fCdsCustomers).AsJSONArray;
	  
      //Convert current record
      jo := TConverter.New.DataSet.Source(fCdsCustomers).AsJSONObject;
	
	  ja.Free;
	  jo.Free;
	end;
    
Convert JSON to DataSet
=======================

First you must have your DataSet and its Fields created.
    
	uses 
      DataSetConverter4D, 
      DataSetConverter4D.Impl;  

	JSON_ARRAY =
			[{
				"Id": 1,
				"Name": "Customers 1",
				"Birth": "2014-01-22 14:05:03"
			}, {
				"Id": 2,
				"Name": "Customers 2",
				"Birth": "2014-01-22 14:05:03"
			}]      
				  
    JSON_OBJECT =
			{
				"Id": 2,
				"Name": "Customers 2",
				"Birth": "2014-01-22 14:05:03"
			}
	var
	  ja: TJSONArray;
	  jo: TJSONObject;
	begin
	  fCdsCustomers.CreateDataSet;
	
	  ja := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON_ARRAY), 0) as TJSONArray;
	  jo := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(JSON_OBJECT), 0) as TJSONObject;
	
	  //Convert one record
      TConverter.New.JSON(jo).ToDataSet(fCdsCustomers);
	
	  fCdsCustomers.EmptyDataSet;
	
      //Convert all records
	  TConverter.New.JSON.Source(ja).ToDataSet(fCdsCustomers);
	
	  ja.Free;
	  jo.Free;
	end;

Using DataSetConverter4D
============================

Using this library will is very simple, you simply add the Search Path of your IDE or your project the following directories:

- DataSetConverter4Delphi\src\

Analyze the unit tests they will assist you.