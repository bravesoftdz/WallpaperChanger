unit WpcStatements;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  Fgl, DateUtils,
  WpcStatementProperties,
  WpcScriptCommons,
  WpcCommonTypes,
  WpcWallpaperStyles,
  WpcExceptions;

type

  { IWpcScriptStatement }

  IWpcBaseScriptStatement = class
  public
    function GetId() : TWpcStatemetId; virtual; abstract;
  end;

  { TWpcWaitStatement }

  TWpcWaitStatement = class(IWpcBaseScriptStatement)
  private
    FDelay       : TWpcDelayStatementProperty;
    FProbability : TWpcProbabilityStatementProperty;
    FTimes       : TWpcTimesStatementProperty;
  public
    constructor Create(Delay : LongWord);
    destructor Destroy(); override;
  public
    procedure SetDelay(Delay : LongWord);
    function GetDelay() : LongWord;
    procedure SetProbability(Probability : Byte);
    function GetProbability() : Byte;
    procedure SetTimes(Times : LongWord);
    function GetTimes() : LongWord;

    function GetId() : TWpcStatemetId; override;
  end;

  { TWpcWallpaperStatement }

  TWpcWallpaperStatement = class(IWpcBaseScriptStatement)
  private
    FImage       : TWpcImage;
    FStyle       : TWallpaperStyle;
    FDelay       : TWpcDelayStatementProperty;
    FProbability : TWpcProbabilityStatementProperty;
  public
    constructor Create(Image : TWpcImage);
    destructor Destroy(); override;
  public
    procedure SetImage(Image : TWpcImage);
    function GetImage() : TWpcImage;
    procedure SetStyle(Style : TWallpaperStyle);
    function GetStyle() : TWallpaperStyle;
    procedure SetDelay(Delay : LongWord);
    function GetDelay() : LongWord;
    procedure SetProbability(Probability : Byte);
    function GetProbability() : Byte;

    function GetId() : TWpcStatemetId; override;
  end;

  { TWpcStopStatement }

  TWpcStopStatement = class(IWpcBaseScriptStatement)
  private
    FProbability : TWpcProbabilityStatementProperty;
  public
    constructor Create();
    destructor Destroy(); override;
  public
    procedure SetProbability(Probability : Byte);
    function GetProbability() : Byte;

    function GetId() : TWpcStatemetId; override;
  end;

  { IWpcBranchReferrer }

  IWpcBranchReferrer = class abstract(IWpcBaseScriptStatement)
  protected
    FBarnchName : String;
  public
    procedure SetBarnchName(BranchName : String);
    function GetBranchName() : String;
  end;

  { TWpcSwitchBranch }

  TWpcSwitchBranchStatement = class(IWpcBranchReferrer)
  private
    FProbability : TWpcProbabilityStatementProperty;
  public
    constructor Create(BranchName : String);
    destructor Destroy(); override;
  public
    procedure SetProbability(Probability : Byte);
    function GetProbability() : Byte;

    function GetId() : TWpcStatemetId; override;
  end;

  { TWpcUseBranchStatement }

  TWpcUseBranchStatement = class(TWpcSwitchBranchStatement)
  private
    FTimes : TWpcTimesStatementProperty;
  public
    constructor Create(BranchName : String);
    destructor Destroy(); override;
  public
    procedure SetTimes(Times : LongWord);
    function GetTimes() : LongWord;

    function GetId() : TWpcStatemetId; override;
  end;

  { TWpcChooserItem }

  // This class should be located inside TWpcAbstarctChooserStatement and
  // Statement field should be generic filed (exactly as T in TWpcAbstarctChooserStatement),
  // but due to limitations of Free Pascal and fgl it is here along with comparator function.
  TWpcChooserItem = class(TObject)
  public
     Statement : IWpcBaseScriptStatement;
     Weight    : LongWord; // All TWpcAbstarctChooserStatement.Selector types are converted into sequental values
  end;

  TListOfChooserItems = specialize TFPGList<TWpcChooserItem>;

  { IWpcChooserItems }

  IWpcChooserItems = class abstract(IWpcBaseScriptStatement)
    function GetItems() : TListOfChooserItems; virtual; abstract;
  end;

  { TWpcAbstarctChooserStatement }

  TWpcSelector = (S_WEIGHT, S_SEASON, S_WEEKDAY, S_MONTH, S_DATE, S_TIME, S_DATETIME);

  TWpcSelectorValueHolder = record
    case Byte of
      1: (Weight : LongWord);
      2: (DateTime : TDateTime);
      3: (Sequential : Integer);
  end;

  generic TWpcAbstarctChooserStatement<T : IWpcBaseScriptStatement> = class abstract(IWpcChooserItems)
  protected
    FSelector    : TWpcSelector;
    FItems       : TListOfChooserItems;
    FFinished    : Boolean; // Locks AddItem after ChooseItem call
    FTotalWeight : LongWord; // Is used to cache sum of item's weights
  public
    constructor Create(Selector : TWpcSelector);
    destructor Destroy(); override;
  public
    function GetSelector() : TWpcSelector;
    function GetItems() : TListOfChooserItems; override;
    procedure AddItem(Item : T; SelectorValue : TWpcSelectorValueHolder);
    function ChooseItem(): T;
  protected
    function ChooseItemByWeight() : T;
    function ChooseItemBySeason() : T;

    function ChooseItemByCurrentSequentialValue(CurrentValue : LongWord) : T;
    function ConvertToSequentialValue(DateTimeValue : TDateTime) : LongWord;

    function GetTotalWeight(): LongWord;
  private
    procedure AddWeightItem(Item : T; Weight : LongWord);
    procedure AddDateTimeItem(Item : T; DateTime : TDateTime);
    procedure AddSequentialItem(Item : T; SequentialNumber : Integer);

    procedure EnsureNoDuplicateSelectorValueExists(SelectorValue : LongWord);
    function FindItemByWeight(Weight : LongWord) : Integer;
  end;

  { TWpcWallpaperChooserStatement }

  TWpcWallpaperChooserStatement = class(specialize TWpcAbstarctChooserStatement<TWpcWallpaperStatement>)
  public
    function GetId() : TWpcStatemetId; override;
  end;

  { TWpcSwitchBranchChooserStatement }

  TWpcSwitchBranchChooserStatement = class(specialize TWpcAbstarctChooserStatement<TWpcSwitchBranchStatement>)
  public
    function GetId() : TWpcStatemetId; override;
  end;

  { TWpcUseBranchChooserStatement }

  TWpcUseBranchChooserStatement = class(specialize TWpcAbstarctChooserStatement<TWpcUseBranchStatement>)
  public
    function GetId() : TWpcStatemetId; override;
  end;

  { TWpcBranchStatement }

  TListOfBranchStatements = specialize TFPGList<IWpcBaseScriptStatement>;

  TWpcBranchStatement = class(IWpcBaseScriptStatement)
  private
    FStatements : TListOfBranchStatements;
    FBranchName : String;
  public
    constructor Create(BranchName : String);
    destructor Destroy(); override;
  public
    procedure AddStatement(Statement : IWpcBaseScriptStatement);
    function GetStatement(StatementNumber : Integer) : IWpcBaseScriptStatement;
    function GetBranchStatements() : TListOfBranchStatements;
    function CountStatements() : Integer;
    function GetName() : String;

    function GetId() : TWpcStatemetId; override;
  end;

  // Due to Free Pascal limitations it is here, but should be in implementation section.
  function ComparatorTWpcChooserItem(const Item1, Item2 : TWpcChooserItem) : Integer;


implementation


{ TWpcWaitStatement }

function TWpcWaitStatement.GetId() : TWpcStatemetId;
begin
  Result := WPC_WAIT_STATEMENT_ID;
end;

constructor TWpcWaitStatement.Create(Delay : LongWord);
begin
  FDelay := TWpcDelayStatementProperty.Create();
  FProbability := TWpcProbabilityStatementProperty.Create();
  FTimes := TWpcTimesStatementProperty.Create();

  FDelay.Delay := Delay;
end;

destructor TWpcWaitStatement.Destroy();
begin
  FDelay.Free();
  FProbability.Free();
  FTimes.Free();
  inherited Destroy;
end;

procedure TWpcWaitStatement.SetDelay(Delay : LongWord);
begin
  FDelay.Delay := Delay;
end;

function TWpcWaitStatement.GetDelay() : LongWord;
begin
   Result := FDelay.Delay;
end;

procedure TWpcWaitStatement.SetProbability(Probability : Byte);
begin
  FProbability.Probability := Probability;
end;

function TWpcWaitStatement.GetProbability() : Byte;
begin
  Result := FProbability.Probability;
end;

procedure TWpcWaitStatement.SetTimes(Times : LongWord);
begin
  FTimes.Times := Times;
end;

function TWpcWaitStatement.GetTimes() : LongWord;
begin
  Result := FTimes.Times;
end;

{ TWpcWallpaperStatement }

function TWpcWallpaperStatement.GetId() : TWpcStatemetId;
begin
  Result := WPC_WALLPAPER_STATEMENT_ID;
end;

constructor TWpcWallpaperStatement.Create(Image : TWpcImage);
begin
  if (Image = nil) then
    raise TWpcIllegalArgumentException.Create('Wallpaper image is mandatory.');
  FImage := Image;
  FDelay := TWpcDelayStatementProperty.Create();
  FProbability := TWpcProbabilityStatementProperty.Create();
end;

destructor TWpcWallpaperStatement.Destroy();
begin
  FImage.Free();
  FDelay.Free();
  FProbability.Free();
  inherited Destroy();
end;

procedure TWpcWallpaperStatement.SetImage(Image : TWpcImage);
begin
  if (Image <> nil) then
    FImage := Image;
end;

function TWpcWallpaperStatement.GetImage() : TWpcImage;
begin
  Result := FImage;
end;

procedure TWpcWallpaperStatement.SetStyle(Style : TWallpaperStyle);
begin
  FStyle := Style;
end;

function TWpcWallpaperStatement.GetStyle() : TWallpaperStyle;
begin
  Result := FStyle;
end;

procedure TWpcWallpaperStatement.SetDelay(Delay : LongWord);
begin
  FDelay.Delay := Delay;
end;

function TWpcWallpaperStatement.GetDelay() : LongWord;
begin
  Result := FDelay.Delay;
end;

procedure TWpcWallpaperStatement.SetProbability(Probability : Byte);
begin
  FProbability.Probability := Probability;
end;

function TWpcWallpaperStatement.GetProbability() : Byte;
begin
  Result := FProbability.Probability;
end;

{ TWpcStopStatement }

function TWpcStopStatement.GetId() : TWpcStatemetId;
begin
  Result := WPC_STOP_STATEMENT_ID;
end;

constructor TWpcStopStatement.Create();
begin
  FProbability := TWpcProbabilityStatementProperty.Create();
end;

destructor TWpcStopStatement.Destroy();
begin
  FProbability.Free();
  inherited Destroy();
end;

procedure TWpcStopStatement.SetProbability(Probability : Byte);
begin
  FProbability.Probability := Probability;
end;

function TWpcStopStatement.GetProbability() : Byte;
begin
  Result := FProbability.Probability;
end;

{ IWpcBranchReferrer }

procedure IWpcBranchReferrer.SetBarnchName(BranchName : String);
begin
  FBarnchName := BranchName;
end;

function IWpcBranchReferrer.GetBranchName() : String;
begin
  Result := FBarnchName;
end;

{ TWpcSwitchBranchStatement }

function TWpcSwitchBranchStatement.GetId() : TWpcStatemetId;
begin
  Result := WPC_SWITCH_BRANCH_STATEMENT_ID;
end;

constructor TWpcSwitchBranchStatement.Create(BranchName : String);
begin
  FBarnchName := BranchName;
  FProbability := TWpcProbabilityStatementProperty.Create();
end;

destructor TWpcSwitchBranchStatement.Destroy();
begin
  FProbability.Free();
  inherited Destroy();
end;

procedure TWpcSwitchBranchStatement.SetProbability(Probability : Byte);
begin
  FProbability.Probability := Probability;
end;

function TWpcSwitchBranchStatement.GetProbability() : Byte;
begin
  Result := FProbability.Probability;
end;

{ TWpcUseBranchStatement }

function TWpcUseBranchStatement.GetId() : TWpcStatemetId;
begin
  Result := WPC_USE_BRANCH_STATEMENT_ID;
end;

constructor TWpcUseBranchStatement.Create(BranchName : String);
begin
  FTimes := TWpcTimesStatementProperty.Create();
  inherited Create(BranchName);
end;

destructor TWpcUseBranchStatement.Destroy();
begin
  FTimes.Free();
  inherited Destroy();
end;

procedure TWpcUseBranchStatement.SetTimes(Times : LongWord);
begin
  FTimes.Times := Times;
end;

function TWpcUseBranchStatement.GetTimes() : LongWord;
begin
  Result := FTimes.Times;
end;

{ TWpcAbstarctChooserStatement }

constructor TWpcAbstarctChooserStatement.Create(Selector : TWpcSelector);
begin
  FFinished := False;
  FSelector := Selector;
  FItems := TListOfChooserItems.Create();
end;

destructor TWpcAbstarctChooserStatement.Destroy();
var
  Item : TWpcChooserItem;
begin
  for Item in FItems do begin
    Item.Statement.Free();
    Item.Free();
  end;
  FItems.Free();
  inherited Destroy();
end;

function TWpcAbstarctChooserStatement.GetSelector() : TWpcSelector;
begin
  Result := FSelector;
end;

{
  Returns Chooser items. Any changes in returned list will affect the chooser.
}
function TWpcAbstarctChooserStatement.GetItems() : TListOfChooserItems;
begin
  Result := FItems;
end;

{
  Adds an item to the Chooser list.
  Depending on Chooser selector, selector value is interpretted in different ways:
   - WEIGHT selector:
       as a weight of item
   - S_SEASON and S_WEEKDAY:
       as a sequential number of the specified selector
   - S_MONTH, S_DATE, S_TIME, S_DATETIME
       as a DateTime encoded into FileDate
}
procedure TWpcAbstarctChooserStatement.AddItem(Item : T; SelectorValue : TWpcSelectorValueHolder);
begin
  if (FFinished) then
    raise TWpcUseErrorException.Create('This container is completed');

  if (FSelector = TWpcSelector.S_WEIGHT) then
    AddWeightItem(Item, SelectorValue.Weight)
  else if (FSelector in [S_SEASON, S_MONTH, S_WEEKDAY]) then
    AddSequentialItem(Item, SelectorValue.Sequential)
  else if (FSelector in [S_DATE, S_TIME, S_DATETIME]) then
    AddDateTimeItem(Item, SelectorValue.DateTime)
  else
    raise TWpcIllegalArgumentException.Create('Unknown selector type.');
end;

{
  Returns chose item. Can be used many times. Each call will cause reselect.
  After call of this method, calling of AddItem will couse an error.
}
function TWpcAbstarctChooserStatement.ChooseItem() : T;
begin
  if (FItems.Count < 2) then
    raise TWpcUseErrorException.Create('Choose statement should contain at least 2 elements');
  if (not FFinished) then begin
    FFinished := True;
    if (FSelector = S_WEIGHT) then
      FTotalWeight := GetTotalWeight()
    else
      FItems.Sort(@ComparatorTWpcChooserItem);
  end;

  case FSelector of
    S_WEIGHT:   Result := ChooseItemByWeight();
    S_SEASON:   Result := ChooseItemBySeason();
    S_WEEKDAY:  Result := ChooseItemByCurrentSequentialValue(DayOfWeek(Now()));
    S_MONTH:    Result := ChooseItemByCurrentSequentialValue(MonthOf(Now()));
    S_DATE:     Result := ChooseItemByCurrentSequentialValue(DayOfTheYear(Now()));
    S_TIME:     Result := ChooseItemByCurrentSequentialValue(SecondOfTheDay(Now()));
    S_DATETIME: Result := ChooseItemByCurrentSequentialValue(SecondOfTheYear(Now()));
  end;
end;

{
  This function selects value from the items list by random but proportionally
  to the items weights.
}
function TWpcAbstarctChooserStatement.ChooseItemByWeight() : T;
var
  ChoseNumber : Integer;
  Sum         : Integer;
  i           : Integer;
begin
  ChoseNumber := Random(FTotalWeight) + 1;
  Sum := 0;
  for i:=0 to (FItems.Count - 1) do begin
    Sum := Sum + FItems[i].Weight;
    if (Sum >= ChoseNumber) then break;
  end;
  // Cast is safe here, because Add methods use T in its argument
  Result := T(FItems[i].Statement);
end;

function TWpcAbstarctChooserStatement.ChooseItemBySeason() : T;
var
  CurrentSeason : LongWord;
begin
  // 1 - Winter, .. , 4 - Autumn
  case MonthOf(Now()) of
      1,2,12:  CurrentSeason := 1;
      3,4,5:   CurrentSeason := 2;
      6,7,8:   CurrentSeason := 3;
      9,10,11: CurrentSeason := 4;
  end;
  Result := ChooseItemByCurrentSequentialValue(CurrentSeason);
end;

{
  This function selects value from the items list which correspond current value,
  i.e. searches for item with >= value than given (current).
  Note, that list 'is cycled', i.e. if given value is less than first then last
  item will be returned.
  Also items list should be sorted before first call.
}
function TWpcAbstarctChooserStatement.ChooseItemByCurrentSequentialValue(CurrentValue : LongWord) : T;
var
  i : Integer;
begin
  // finds next item number
  for i:=0 to (FItems.Count - 1) do
    if (FItems[i].Weight > CurrentValue) then break;

  // now previous item is the wanted one
  if (i = 0) then
    i := FItems.Count - 1
  else
    Dec(i);

  // Cast is safe here, because Add method use T in its argument
  Result := T(FItems[i].Statement);
end;

{
  Converts given date-time to its sequental value,
  Convertation algorithm depends on FChooseBy:
    MONTH: 1 - January, .. , 12 - December
    DATE: to sequential number of day in a year
    TIME: to sequential number of second in a day
    DATETIME: to sequential number of second in a year
}
function TWpcAbstarctChooserStatement.ConvertToSequentialValue(DateTimeValue : TDateTime) : LongWord;
begin
  case (FSelector) of
    S_DATE:     Result := DayOfTheYear(DateTimeValue);
    S_TIME:     Result := SecondOfTheDay(DateTimeValue);
    S_DATETIME: Result := SecondOfTheYear(DateTimeValue);
    else
      raise TWpcUseErrorException.Create('Cannot convert selector to sequential value.');
  end;
end;

function TWpcAbstarctChooserStatement.GetTotalWeight() : LongWord;
var
  Item        : TWpcChooserItem;
  TotalWeight : LongWord;
begin
  TotalWeight := 0;
  for Item in FItems do
    TotalWeight := TotalWeight + Item.Weight;
  Result := TotalWeight;
end;

procedure TWpcAbstarctChooserStatement.AddWeightItem(Item : T; Weight : LongWord);
var
  ChooserItem : TWpcChooserItem;
begin
  ChooserItem := TWpcChooserItem.Create();
  ChooserItem.Statement := Item;
  ChooserItem.Weight := Weight;
  FItems.Add(ChooserItem);
end;

procedure TWpcAbstarctChooserStatement.AddDateTimeItem(Item : T; DateTime : TDateTime);
var
  ChooserItem : TWpcChooserItem;
begin
  ChooserItem := TWpcChooserItem.Create();
  ChooserItem.Statement := Item;
  ChooserItem.Weight := ConvertToSequentialValue(DateTime);
  EnsureNoDuplicateSelectorValueExists(ChooserItem.Weight);
  FItems.Add(ChooserItem);
end;

procedure TWpcAbstarctChooserStatement.AddSequentialItem(Item : T; SequentialNumber : Integer);
var
  ChooserItem : TWpcChooserItem;
begin
  ChooserItem := TWpcChooserItem.Create();
  ChooserItem.Statement := Item;
  ChooserItem.Weight := SequentialNumber;
  EnsureNoDuplicateSelectorValueExists(ChooserItem.Weight);
  FItems.Add(ChooserItem);
end;

procedure TWpcAbstarctChooserStatement.EnsureNoDuplicateSelectorValueExists(SelectorValue : LongWord);
begin
  if (FindItemByWeight(SelectorValue) <> -1) then
    raise TWpcIllegalArgumentException.Create('Duplicate selector value: "' + IntToStr(SelectorValue) + '".');
end;

{
  Findsfor item with given weight and returns its index.
  If specified item not found -1 will be returned.
}
function TWpcAbstarctChooserStatement.FindItemByWeight(Weight : LongWord) : Integer;
var
  i : Integer;
begin
  for i:=0 to (FItems.Count - 1) do
    if (FItems[i].Weight = Weight) then begin
      Result := i;
      exit;
    end;
  Result := -1;
end;

// Comparator for TWpcChooserItem
function ComparatorTWpcChooserItem(const Item1, Item2 : TWpcChooserItem) : Integer;
begin
  if (Item1.Weight > Item2.Weight) then
    Result := 1
  else if (Item1.Weight < Item2.Weight) then
    Result := -1
  else
    Result := 0
end;

{ TWpcWallpaperChooserStatement }

function TWpcWallpaperChooserStatement.GetId() : TWpcStatemetId;
begin
  Result := WPC_WALLPAPER_CHOOSER_STATEMENT_ID;
end;

{ TWpcSwitchBranchChooserStatement }

function TWpcSwitchBranchChooserStatement.GetId() : TWpcStatemetId;
begin
  Result := WPC_BRANCH_TO_SWITCH_CHOOSER_STATEMENT_ID;
end;

{ TWpcUseBranchChooserStatement }

function TWpcUseBranchChooserStatement.GetId() : TWpcStatemetId;
begin
  Result := WPC_BRANCH_TO_USE_CHOOSER_STATEMENT_ID;
end;

{ TWpcBranchStatement }

function TWpcBranchStatement.GetId() : TWpcStatemetId;
begin
  Result := WPC_BRANCH_STATEMENT_ID;
end;

constructor TWpcBranchStatement.Create(BranchName : String);
begin
  FBranchName := BranchName;
  FStatements := TListOfBranchStatements.Create();
end;

destructor TWpcBranchStatement.Destroy();
var
  Statement : IWpcBaseScriptStatement;
begin
  for Statement in FStatements do
    Statement.Free();
  FStatements.Free();
  inherited Destroy();
end;

procedure TWpcBranchStatement.AddStatement(Statement : IWpcBaseScriptStatement);
begin
  FStatements.Add(Statement);
end;

function TWpcBranchStatement.GetStatement(StatementNumber : Integer) : IWpcBaseScriptStatement;
begin
  Result := FStatements[StatementNumber];
end;

function TWpcBranchStatement.GetBranchStatements() : TListOfBranchStatements;
begin
  Result := FStatements;
end;

function TWpcBranchStatement.CountStatements() : Integer;
begin
  Result := FStatements.Count;
end;

function TWpcBranchStatement.GetName() : String;
begin
  Result := FBranchName;
end;


end.

