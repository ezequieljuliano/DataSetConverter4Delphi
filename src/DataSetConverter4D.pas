unit DataSetConverter4D;

interface

uses
  System.SysUtils,
  System.JSON,
  Data.DB;

type

  EDataSetConverterException = class(Exception);

  TBooleanFieldType = (bfUnknown, bfBoolean, bfInteger);
  TDataSetFieldType = (dfUnknown, dfJSONObject, dfJSONArray);

  IDataSetConverter = interface
    ['{8D995E50-A1DC-4426-A603-762E1387E691}']
    function Source(dataSet: TDataSet): IDataSetConverter; overload;
    function Source(dataSet: TDataSet; const owns: Boolean): IDataSetConverter; overload;

    function AsJSONObject: TJSONObject;
    function AsJSONArray: TJSONArray;
    function AsJSONStructure: TJSONArray;
  end;

  IJSONConverter = interface
    ['{1B020937-438E-483F-ACB1-44B8B2707500}']
    function Source(JSON: TJSONObject): IJSONConverter; overload;
    function Source(JSON: TJSONObject; const owns: Boolean): IJSONConverter; overload;

    function Source(JSON: TJSONArray): IJSONConverter; overload;
    function Source(JSON: TJSONArray; const owns: Boolean): IJSONConverter; overload;

    procedure ToDataSet(dataSet: TDataSet; const OwnerControl: Boolean = False);
    procedure ToRecord(dataSet: TDataSet; const OwnerControl: Boolean = False);
    procedure ToStructure(dataSet: TDataSet);
  end;

  IConverter = interface
    ['{52A3BE1E-5116-4A9A-A7B6-3AF0FCEB1D8E}']
    function dataSet: IDataSetConverter; overload;
    function dataSet(dataSet: TDataSet): IDataSetConverter; overload;
    function dataSet(dataSet: TDataSet; const owns: Boolean): IDataSetConverter; overload;

    function JSON: IJSONConverter; overload;
    function JSON(JSON: TJSONObject): IJSONConverter; overload;
    function JSON(JSON: TJSONObject; const owns: Boolean): IJSONConverter; overload;

    function JSON(JSON: TJSONArray): IJSONConverter; overload;
    function JSON(JSON: TJSONArray; const owns: Boolean): IJSONConverter; overload;
  end;

implementation

end.
