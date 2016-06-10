program DataSetConverter4DTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  DataSetConverter4D in '..\src\DataSetConverter4D.pas',
  DataSetConverter4D.UnitTest in 'DataSetConverter4D.UnitTest.pas',
  DataSetConverter4D.Impl in '..\src\DataSetConverter4D.Impl.pas',
  DataSetConverter4D.Util in '..\src\DataSetConverter4D.Util.pas',
  DataSetConverter4D.Helper in '..\src\DataSetConverter4D.Helper.pas';

{$R *.RES}

begin

  ReportMemoryLeaksOnShutdown := True;

  DUnitTestRunner.RunRegisteredTests;

end.
