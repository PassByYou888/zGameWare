﻿{ * https://zpascal.net                                                        * }
{ * https://github.com/PassByYou888/zAI                                        * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/PascalString                               * }
{ * https://github.com/PassByYou888/zRasterization                             * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zChinese                                   * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zGameWare                                  * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ * https://github.com/PassByYou888/FFMPEG-Header                              * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/InfiniteIoT                                * }
{ * https://github.com/PassByYou888/FastMD5                                    * }
{ ****************************************************************************** }
unit BioDataModule;

{$INCLUDE zDefine.inc}

interface

uses
{$IFDEF FPC}
  FPCGenericStructlist,
{$ENDIF FPC}
  CoreClasses, Geometry2DUnit, NumberBase, BioBase, PascalStrings;

type
  TNMAutomatedManager = class;

  TNumberProcessStyle = (npsInc, npsDec, npsIncMul, npsDecMul);

  TNumberProcessingData = record
    token: TCoreClassObject;
    opValue: Variant;
    Style: TNumberProcessStyle;
    CancelDelayTime: Double;
    Overlap: Boolean;
    TypeID: Integer;
    Priority: Cardinal;
    Processed: Boolean;
  end;

  PDMProcessingData = ^TNumberProcessingData;

  TNMAutomated = class(TCoreClassPersistent)
  private
    FOwner: TNMAutomatedManager;
    FDMSource: TNumberModule;
    FCurrentValueHookIntf: TNumberModuleHookPool;
    FCurrentValueCalcList: TCoreClassList;
  protected
    procedure DMCurrentValueHook(Sender: TNumberModuleHookPool; OLD_: Variant; var New_: Variant);
  private
    function GetCurrentValueCalcData(token: TCoreClassObject): PDMProcessingData;
  public
    constructor Create(Owner_: TNMAutomatedManager; DMSource_: TNumberModule);
    destructor Destroy; override;
    property Owner: TNMAutomatedManager read FOwner write FOwner;
    procedure Progress(deltaTime: Double);
    procedure ChangeProcessStyle(token: TCoreClassObject;
      opValue: Variant; Style: TNumberProcessStyle; CancelDelayTime: Double; Overlap: Boolean; TypeID: Integer; Priority: Cardinal);
    procedure Cancel(token: TCoreClassObject);
    procedure Clear;
  end;

  TNMAutomatedList_Decl = {$IFDEF FPC}specialize {$ENDIF FPC} TGenericsList<TNMAutomated>;

  TNMAutomatedManager = class(TCoreClassPersistent)
  private
    FList: TNMAutomatedList_Decl;
    function GetOrCreate(DMSource_: TNumberModule): TNMAutomated;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Progress(deltaTime: Double);
    procedure Clear;

    procedure PostAutomatedProcess(Style: TNumberProcessStyle;
      DMSource_: TNumberModule; token: TCoreClassPersistent;
      opValue: Variant; Overlap: Boolean; TypeID: Integer; Priority: Cardinal);

    procedure PostAutomatedDelayCancelProcess(Style: TNumberProcessStyle;
      DMSource_: TNumberModule; token: TCoreClassPersistent;
      opValue: Variant; Overlap: Boolean; TypeID: Integer; Priority: Cardinal; CancelDelayTime: Double);

    procedure Delete(DMSource_: TNumberModule; token: TCoreClassObject); overload;
    procedure Delete(token: TCoreClassObject); overload;
  end;

  TBioBaseData = class;

  TDataItem = class(TCoreClassObject)
  private
    FOwner: TBioBaseData;
    FName: SystemString;
    FValue: TNumberModule;

    FIncreaseFromSpell: TNumberModule;
    FIncreasePercentageFromSpell: TNumberModule;
    FReduceFromSpell: TNumberModule;
    FReducePercentageFromSpell: TNumberModule;

    FIncreaseFromEquipment: TNumberModule;
    FIncreasePercentageFromEquipment: TNumberModule;
    FReduceFromEquipment: TNumberModule;
    FReducePercentageFromEquipment: TNumberModule;

    FIncreaseFromAssociate: TNumberModule;
    FIncreasePercentageFromAssociate: TNumberModule;
    FReduceFromAssociate: TNumberModule;
    FReducePercentageFromAssociate: TNumberModule;

    FLastFinalValue: Variant;
    FNeedRecalcFinalValue: Boolean;

    procedure ChangeEvent(Sender: TNumberModuleEventPool; New_: Variant);
  public
    constructor Create(Owner_: TBioBaseData; Name_: SystemString);
    destructor Destroy; override;

    property Owner: TBioBaseData read FOwner;
    property Name: SystemString read FName;

    function GetFinalValue: Variant;
    property FinalValue: Variant read GetFinalValue;

    property Value: TNumberModule read FValue;

    property IncreaseFromSpell: TNumberModule read FIncreaseFromSpell;
    property IncreasePercentageFromSpell: TNumberModule read FIncreasePercentageFromSpell;
    property ReduceFromSpell: TNumberModule read FReduceFromSpell;
    property ReducePercentageFromSpell: TNumberModule read FReducePercentageFromSpell;

    property IncreaseFromEquipment: TNumberModule read FIncreaseFromEquipment;
    property IncreasePercentageFromEquipment: TNumberModule read FIncreasePercentageFromEquipment;
    property ReduceFromEquipment: TNumberModule read FReduceFromEquipment;
    property ReducePercentageFromEquipment: TNumberModule read FReducePercentageFromEquipment;

    property IncreaseFromAssociate: TNumberModule read FIncreaseFromAssociate;
    property IncreasePercentageFromAssociate: TNumberModule read FIncreasePercentageFromAssociate;
    property ReduceFromAssociate: TNumberModule read FReduceFromAssociate;
    property ReducePercentageFromAssociate: TNumberModule read FReducePercentageFromAssociate;
  end;

  TPrimaryAttribute = (paStrength, paDexterous, paIntelligence, paNone);

  TDamageType = (dtPhysics, dtFire, dtCold, dtPoison, dtArcane);

  TDataID = (
    diStrength,
    diDexterous,
    diIntelligence,
    diMinDamage,
    diMaxDamage,
    diPhysicsDamage,
    diFireDamage,
    diColdDamage,
    diPoisonDamage,
    diArcaneDamage,
    diAttackSpeed,
    diChanceToDodge,
    diChanceToBlock,
    diBlockSuccessDamageReduce,
    diBulletAccurate,
    diReceiveExtraDamage,
    diArmor,
    diPhysicsResistance,
    diFireResistance,
    diColdResistance,
    diPoisonResistance,
    diArcaneResistance,
    diVitality,
    diMaxHP,
    diHPRegeneration,
    diMaxPower,
    diPowerRegeneration,
    diMovementSpeed,
    diCooldownReduct
    );

  TIncreaseDataPostStyle = (
    dipsValue,
    dipsSpell, dipsSpellPercentage,
    dipsEquipment, dipsEquipmentPercentage,
    dipsAssociate, dipsAssociatePercentage
    );

  TBioBaseData = class(TCoreClassObject)
  private
    FOwner: TBioBase;
    FDataItemList: TCoreClassListForObj;
    FNMList: TNumberModulePool;
    FNMAutomatedManager: TNMAutomatedManager;
    FPrimaryAttribute: TPrimaryAttribute;
    FUpdateCounter: Integer;
  protected
    FStrength: TDataItem;
    FDexterous: TDataItem;
    FIntelligence: TDataItem;

    FMinDamage: TDataItem;
    FMaxDamage: TDataItem;

    FPhysicsDamage: TDataItem;
    FFireDamage: TDataItem;
    FColdDamage: TDataItem;
    FPoisonDamage: TDataItem;
    FArcaneDamage: TDataItem;

    FAttackSpeed: TDataItem;
    FChanceToDodge: TDataItem;

    FChanceToBlock: TDataItem;
    FBlockSuccessDamageReduce: TDataItem;

    FBulletAccurate: TDataItem;

    FReceiveExtraDamage: TDataItem;

    FArmor: TDataItem;
    FPhysicsResistance: TDataItem;
    FFireResistance: TDataItem;
    FColdResistance: TDataItem;
    FPoisonResistance: TDataItem;
    FArcaneResistance: TDataItem;

    FVitality: TDataItem;
    FMaxHP: TDataItem;
    FHP: Variant;
    FHPRegeneration: TDataItem;

    FMaxPower: TDataItem;
    FPower: Variant;
    FPowerRegeneration: TDataItem;

    FMovementSpeed: TDataItem;
    FCooldownReduct: TDataItem;

    procedure NumberItemChange(Sender: TDataItem);
  public
    constructor Create(Owner_: TBioBase); overload;
    destructor Destroy; override;

    procedure InitData;

    property Owner: TBioBase read FOwner;

    procedure Progress(deltaTime: Double);
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure RebuildAssociate;
    procedure Clear;

    function GetDataOfID(ID: TDataID): TDataItem;
    function GetDMOfStyle(dItm: TDataItem; Style: TIncreaseDataPostStyle; SeedNumber: Variant): TNumberModule;
    //
    procedure DeletePostFlag(flag: TCoreClassPersistent);
    // post automated overlap value
    procedure PostOverlapData(ID: TDataID; Style: TIncreaseDataPostStyle; flag: TCoreClassPersistent; SeedNumber: Variant);

    // post automated no overlap value
    procedure PostData(ID: TDataID; Style: TIncreaseDataPostStyle;
      flag: TCoreClassPersistent; SeedNumber: Variant; TypeID: Integer; Priority: Cardinal);

    property PrimaryAttribute: TPrimaryAttribute read FPrimaryAttribute write FPrimaryAttribute;

    property Strength: TDataItem read FStrength;
    property Dexterous: TDataItem read FDexterous;
    property Intelligence: TDataItem read FIntelligence;

    property MinDamage: TDataItem read FMinDamage;
    property MaxDamage: TDataItem read FMaxDamage;

    property PhysicsDamage: TDataItem read FPhysicsDamage;
    property FireDamage: TDataItem read FFireDamage;
    property ColdDamage: TDataItem read FColdDamage;
    property PoisonDamage: TDataItem read FPoisonDamage;
    property ArcaneDamage: TDataItem read FArcaneDamage;

    property AttackSpeed: TDataItem read FAttackSpeed;
    property ChanceToDodge: TDataItem read FChanceToDodge;

    property ChanceToBlock: TDataItem read FChanceToBlock;
    property BlockSuccessDamageReduce: TDataItem read FBlockSuccessDamageReduce;

    property BulletAccurate: TDataItem read FBulletAccurate;
    property ReceiveExtraDamage: TDataItem read FReceiveExtraDamage;

    property Armor: TDataItem read FArmor;
    property PhysicsResistance: TDataItem read FPhysicsResistance;
    property FireResistance: TDataItem read FFireResistance;
    property ColdResistance: TDataItem read FColdResistance;
    property PoisonResistance: TDataItem read FPoisonResistance;
    property ArcaneResistance: TDataItem read FArcaneResistance;

    property Vitality: TDataItem read FVitality;
    property MaxHP: TDataItem read FMaxHP;
    property HP: Variant read FHP write FHP;
    property HPRegeneration: TDataItem read FHPRegeneration;

    property MaxPower: TDataItem read FMaxPower;
    property Power: Variant read FPower write FPower;
    property PowerRegeneration: TDataItem read FPowerRegeneration;

    property MovementSpeed: TDataItem read FMovementSpeed;

    property CooldownReduct: TDataItem read FCooldownReduct;
  end;

implementation

procedure TNMAutomated.DMCurrentValueHook(Sender: TNumberModuleHookPool; OLD_: Variant; var New_: Variant);

  function IsMaxPriorityOverlap(ignore: PDMProcessingData): Boolean;
  var
    i: Integer;
    p: PDMProcessingData;
  begin
    Result := True;

    for i := 0 to FCurrentValueCalcList.Count - 1 do
      begin
        p := FCurrentValueCalcList[i];
        if (p <> ignore) and (p^.Processed) then
          if (p^.TypeID = ignore^.TypeID) and (p^.Priority >= ignore^.Priority) then
            begin
              Result := False;
              Exit;
            end;
      end;
  end;

  procedure ImpStyleValue(p: PDMProcessingData);
  begin
    case p^.Style of
      npsInc: New_ := New_ + p^.opValue;
      npsDec: New_ := New_ - p^.opValue;
      npsIncMul: New_ := New_ + FDMSource.OriginValue * p^.opValue;
      npsDecMul: New_ := New_ - FDMSource.OriginValue * p^.opValue;
      else
        Assert(False);
    end;
    p^.Processed := True;
  end;

var
  i: Integer;
  p: PDMProcessingData;
  b: Boolean;
begin
  for i := 0 to FCurrentValueCalcList.Count - 1 do
      PDMProcessingData(FCurrentValueCalcList[i])^.Processed := False;

  for i := 0 to FCurrentValueCalcList.Count - 1 do
    begin
      p := FCurrentValueCalcList[i];
      b := p^.Overlap;
      if not b then
          b := IsMaxPriorityOverlap(p);
      if b then
          ImpStyleValue(p);
    end;
end;

function TNMAutomated.GetCurrentValueCalcData(token: TCoreClassObject): PDMProcessingData;
var
  i: Integer;
begin
  for i := 0 to FCurrentValueCalcList.Count - 1 do
    if PDMProcessingData(FCurrentValueCalcList[i])^.token = token then
      begin
        Result := FCurrentValueCalcList[i];
        Exit;
      end;
  Result := nil;
end;

constructor TNMAutomated.Create(Owner_: TNMAutomatedManager; DMSource_: TNumberModule);
begin
  inherited Create;
  FOwner := Owner_;
  FDMSource := DMSource_;

  FCurrentValueHookIntf := FDMSource.RegisterCurrentValueHook;

  FCurrentValueHookIntf.OnCurrentDMHook := {$IFDEF FPC}@{$ENDIF FPC}DMCurrentValueHook;
  FCurrentValueCalcList := TCoreClassList.Create;
end;

destructor TNMAutomated.Destroy;
begin
  Clear;
  DisposeObject(FCurrentValueCalcList);
  DisposeObject(FCurrentValueHookIntf);
  inherited Destroy;
end;

procedure TNMAutomated.Progress(deltaTime: Double);
var
  i: Integer;
  p: PDMProcessingData;
begin
  i := 0;
  while i < FCurrentValueCalcList.Count do
    begin
      p := FCurrentValueCalcList[i];
      if p^.CancelDelayTime > 0 then
        begin
          if p^.CancelDelayTime - deltaTime <= 0 then
            begin
              Dispose(p);
              FCurrentValueCalcList.Delete(i);
            end
          else
            begin
              p^.CancelDelayTime := p^.CancelDelayTime - deltaTime;
              inc(i);
            end;
        end
      else
          inc(i);
    end;
end;

procedure TNMAutomated.ChangeProcessStyle(token: TCoreClassObject;
  opValue: Variant; Style: TNumberProcessStyle; CancelDelayTime: Double; Overlap: Boolean; TypeID: Integer; Priority: Cardinal);
var
  p: PDMProcessingData;
begin
  p := GetCurrentValueCalcData(token);
  if p = nil then
    begin
      new(p);
      FCurrentValueCalcList.Add(p);
    end;
  p^.token := token;
  p^.opValue := opValue;
  p^.Style := Style;
  p^.CancelDelayTime := CancelDelayTime;
  p^.Overlap := Overlap;
  p^.TypeID := TypeID;
  p^.Priority := Priority;
  p^.Processed := False;
  FDMSource.DoChange;
end;

procedure TNMAutomated.Cancel(token: TCoreClassObject);
var
  i: Integer;
  p: PDMProcessingData;
  NeedUpdate_: Boolean;
begin
  i := 0;
  NeedUpdate_ := False;
  while i < FCurrentValueCalcList.Count do
    begin
      p := FCurrentValueCalcList[i];
      if p^.token = token then
        begin
          Dispose(p);
          FCurrentValueCalcList.Delete(i);
          NeedUpdate_ := True;
        end
      else
          inc(i);
    end;
  if NeedUpdate_ then
      FDMSource.DoChange;
end;

procedure TNMAutomated.Clear;
var
  i: Integer;
begin
  for i := 0 to FCurrentValueCalcList.Count - 1 do
      Dispose(PDMProcessingData(FCurrentValueCalcList[i]));
  FCurrentValueCalcList.Clear;
end;

function TNMAutomatedManager.GetOrCreate(DMSource_: TNumberModule): TNMAutomated;
var
  i: Integer;
begin
  for i := 0 to FList.Count - 1 do
    begin
      Result := FList[i];
      if Result.FDMSource = DMSource_ then
          Exit;
    end;
  Result := TNMAutomated.Create(Self, DMSource_);
  FList.Add(Result);
end;

constructor TNMAutomatedManager.Create;
begin
  inherited Create;
  FList := TNMAutomatedList_Decl.Create;
end;

destructor TNMAutomatedManager.Destroy;
begin
  Clear;
  DisposeObject(FList);
  inherited Destroy;
end;

procedure TNMAutomatedManager.Progress(deltaTime: Double);
var
  i: Integer;
begin
  for i := 0 to FList.Count - 1 do
      FList[i].Progress(deltaTime);
end;

procedure TNMAutomatedManager.Clear;
var
  i: Integer;
begin
  for i := 0 to FList.Count - 1 do
      DisposeObject(FList[i]);
  FList.Clear;
end;

procedure TNMAutomatedManager.PostAutomatedProcess(Style: TNumberProcessStyle;
  DMSource_: TNumberModule; token: TCoreClassPersistent;
  opValue: Variant; Overlap: Boolean; TypeID: Integer; Priority: Cardinal);
begin
  GetOrCreate(DMSource_).ChangeProcessStyle(token, opValue, Style, 0, Overlap, TypeID, Priority);
end;

procedure TNMAutomatedManager.PostAutomatedDelayCancelProcess(Style: TNumberProcessStyle;
  DMSource_: TNumberModule; token: TCoreClassPersistent;
  opValue: Variant; Overlap: Boolean; TypeID: Integer; Priority: Cardinal; CancelDelayTime: Double);
begin
  GetOrCreate(DMSource_).ChangeProcessStyle(token, opValue, Style, CancelDelayTime, Overlap, TypeID, Priority);
end;

procedure TNMAutomatedManager.Delete(DMSource_: TNumberModule; token: TCoreClassObject);
begin
  GetOrCreate(DMSource_).Cancel(token);
end;

procedure TNMAutomatedManager.Delete(token: TCoreClassObject);
var
  i: Integer;
begin
  for i := 0 to FList.Count - 1 do
      FList[i].Cancel(token);
end;

procedure TDataItem.ChangeEvent(Sender: TNumberModuleEventPool; New_: Variant);
begin
  FNeedRecalcFinalValue := True;
  FOwner.NumberItemChange(Self);
end;

constructor TDataItem.Create(Owner_: TBioBaseData; Name_: SystemString);
begin
  Assert(not Owner_.FNMList.Exists(Name_));
  inherited Create;
  FOwner := Owner_;
  FOwner.FDataItemList.Add(Self);
  FName := Name_;
  FValue := FOwner.FNMList[FName];

  FIncreaseFromSpell := FOwner.FNMList[FName + '.IncreaseFromSpell'];
  FIncreasePercentageFromSpell := FOwner.FNMList[FName + '.IncreasePercentageFromSpell'];
  FReduceFromSpell := FOwner.FNMList[FName + '.ReduceFromSpell'];
  FReducePercentageFromSpell := FOwner.FNMList[FName + '.ReducePercentageFromSpell'];

  FIncreaseFromEquipment := FOwner.FNMList[FName + '.IncreaseFromEquipment'];
  FIncreasePercentageFromEquipment := FOwner.FNMList[FName + '.IncreasePercentageFromEquipment'];
  FReduceFromEquipment := FOwner.FNMList[FName + '.ReduceFromEquipment'];
  FReducePercentageFromEquipment := FOwner.FNMList[FName + '.ReducePercentageFromEquipment'];

  FIncreaseFromAssociate := FOwner.FNMList[FName + '.IncreaseFromAssociate'];
  FIncreasePercentageFromAssociate := FOwner.FNMList[FName + '.IncreasePercentageFromAssociate'];
  FReduceFromAssociate := FOwner.FNMList[FName + '.ReduceFromAssociate'];
  FReducePercentageFromAssociate := FOwner.FNMList[FName + '.ReducePercentageFromAssociate'];

  FValue.OriginValue := 0;

  FIncreaseFromSpell.OriginValue := 0;
  FIncreasePercentageFromSpell.OriginValue := 0;
  FReduceFromSpell.OriginValue := 0;
  FReducePercentageFromSpell.OriginValue := 0;

  FIncreaseFromEquipment.OriginValue := 0;
  FIncreasePercentageFromEquipment.OriginValue := 0;
  FReduceFromEquipment.OriginValue := 0;
  FReducePercentageFromEquipment.OriginValue := 0;

  FIncreaseFromAssociate.OriginValue := 0;
  FIncreasePercentageFromAssociate.OriginValue := 0;
  FReduceFromAssociate.OriginValue := 0;
  FReducePercentageFromAssociate.OriginValue := 0;

{$IFDEF FPC}
  FValue.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;

  FIncreaseFromSpell.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;
  FIncreasePercentageFromSpell.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;
  FReduceFromSpell.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;
  FReducePercentageFromSpell.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;

  FIncreaseFromEquipment.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;
  FIncreasePercentageFromEquipment.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;
  FReduceFromEquipment.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;
  FReducePercentageFromEquipment.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;

  FIncreaseFromAssociate.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;
  FIncreasePercentageFromAssociate.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;
  FReduceFromAssociate.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;
  FReducePercentageFromAssociate.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := @ChangeEvent;
{$ELSE}
  FValue.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;

  FIncreaseFromSpell.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;
  FIncreasePercentageFromSpell.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;
  FReduceFromSpell.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;
  FReducePercentageFromSpell.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;

  FIncreaseFromEquipment.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;
  FIncreasePercentageFromEquipment.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;
  FReduceFromEquipment.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;
  FReducePercentageFromEquipment.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;

  FIncreaseFromAssociate.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;
  FIncreasePercentageFromAssociate.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;
  FReduceFromAssociate.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;
  FReducePercentageFromAssociate.RegisterCurrentValueChangeAfterEvent.OnCurrentDMEvent := ChangeEvent;
{$ENDIF}
  FLastFinalValue := 0;
  FNeedRecalcFinalValue := True;
end;

destructor TDataItem.Destroy;
begin
  inherited Destroy;
end;

function TDataItem.GetFinalValue: Variant;
var
  vInc, vDec, vIncP, vDecP, v: Variant;
begin
  if FNeedRecalcFinalValue then
    begin
      vInc := FIncreaseFromSpell.AsValue + FIncreaseFromEquipment.AsValue + FIncreaseFromAssociate.AsValue;
      vDec := FReduceFromSpell.AsValue + FReduceFromEquipment.AsValue + FReduceFromAssociate.AsValue;
      vIncP := FIncreasePercentageFromSpell.AsValue + FIncreasePercentageFromEquipment.AsValue + FIncreasePercentageFromAssociate.AsValue;
      vDecP := FReducePercentageFromSpell.AsValue + FReducePercentageFromEquipment.AsValue + FReducePercentageFromAssociate.AsValue;
      v := FValue.AsValue + (vInc - vDec);

      FLastFinalValue := v + v * ((vIncP - vDecP) * 0.01);

      FNeedRecalcFinalValue := False;
    end;
  Result := FLastFinalValue;
end;

procedure TBioBaseData.NumberItemChange(Sender: TDataItem);
begin
  if FUpdateCounter > 0 then
      Exit;
  RebuildAssociate;
end;

constructor TBioBaseData.Create(Owner_: TBioBase);
begin
  inherited Create;
  FOwner := Owner_;
  FDataItemList := TCoreClassListForObj.Create;
  FNMList := TNumberModulePool.Create;
  FNMAutomatedManager := TNMAutomatedManager.Create;
  FPrimaryAttribute := paNone;
  FUpdateCounter := 0;

  FStrength := TDataItem.Create(Self, 'Strength');
  FDexterous := TDataItem.Create(Self, 'Dexterous');
  FIntelligence := TDataItem.Create(Self, 'Intelligence');

  FMinDamage := TDataItem.Create(Self, 'MinDamage');
  FMaxDamage := TDataItem.Create(Self, 'MaxDamage');

  FPhysicsDamage := TDataItem.Create(Self, 'PhysicsDamage');
  FFireDamage := TDataItem.Create(Self, 'FireDamage');
  FColdDamage := TDataItem.Create(Self, 'ColdDamage');
  FPoisonDamage := TDataItem.Create(Self, 'PoisonDamage');
  FArcaneDamage := TDataItem.Create(Self, 'ArcaneDamage');

  FAttackSpeed := TDataItem.Create(Self, 'AttackSpeed');
  FChanceToBlock := TDataItem.Create(Self, 'ChanceToBlock');
  FChanceToDodge := TDataItem.Create(Self, 'ChanceToDodge');
  FBlockSuccessDamageReduce := TDataItem.Create(Self, 'BlockSuccessDamageReduce');

  FBulletAccurate := TDataItem.Create(Self, 'BulletAccurate');

  FReceiveExtraDamage := TDataItem.Create(Self, 'ReceiveExtraDamage');

  FArmor := TDataItem.Create(Self, 'Armor');
  FPhysicsResistance := TDataItem.Create(Self, 'PhysicsResistance');
  FFireResistance := TDataItem.Create(Self, 'FireResistance');
  FColdResistance := TDataItem.Create(Self, 'ColdResistance');
  FPoisonResistance := TDataItem.Create(Self, 'PoisonResistance');
  FArcaneResistance := TDataItem.Create(Self, 'ArcaneResistance');

  FVitality := TDataItem.Create(Self, 'Vitality');
  FMaxHP := TDataItem.Create(Self, 'MaxHP');
  FHP := 1.0;
  FHPRegeneration := TDataItem.Create(Self, 'HPRegeneration');

  FMaxPower := TDataItem.Create(Self, 'MaxPower');
  FPower := 0.0;
  FPowerRegeneration := TDataItem.Create(Self, 'PowerRegeneration');

  FMovementSpeed := TDataItem.Create(Self, 'MovementSpeed');

  FCooldownReduct := TDataItem.Create(Self, 'CooldownReduct');

  InitData;
  RebuildAssociate;
end;

destructor TBioBaseData.Destroy;
begin
  Clear;
  DisposeObject(FNMAutomatedManager);
  DisposeObject(FNMList);
  inherited Destroy;
end;

procedure TBioBaseData.InitData;
begin
end;

procedure TBioBaseData.Progress(deltaTime: Double);
begin
  FNMAutomatedManager.Progress(deltaTime);

  if HP < MaxHP.FinalValue then
      HP := HP + (HPRegeneration.FinalValue * deltaTime);
  if HP > MaxHP.FinalValue then
      HP := MaxHP.FinalValue;

  if Power < MaxPower.FinalValue then
      Power := Power + (PowerRegeneration.FinalValue * deltaTime);
  if Power > MaxPower.FinalValue then
      Power := MaxPower.FinalValue;
end;

procedure TBioBaseData.BeginUpdate;
begin
  inc(FUpdateCounter);
end;

procedure TBioBaseData.EndUpdate;
begin
  dec(FUpdateCounter);
  if FUpdateCounter <= 0 then
    begin
      FUpdateCounter := 0;
      RebuildAssociate;
    end;
end;

procedure TBioBaseData.RebuildAssociate;
var
  i: Integer;
  v: Variant;
begin
  for i := 0 to FDataItemList.Count - 1 do
      TDataItem(FDataItemList[i]).FNeedRecalcFinalValue := True;

  // 100体能+1hp回复
  HPRegeneration.IncreaseFromAssociate.DirectValue := Vitality.FinalValue * 0.01;
  // 1体能+5hp最大生命
  MaxHP.IncreaseFromAssociate.DirectValue := Vitality.FinalValue * 5;
  if HP > MaxHP.FinalValue then
      HP := MaxHP.FinalValue;

  // 100智力+1mp回复
  PowerRegeneration.IncreaseFromAssociate.DirectValue := Intelligence.FinalValue * 0.01;
  // 1智力+0.5mp最大魔法
  MaxPower.IncreaseFromAssociate.DirectValue := Intelligence.FinalValue * 0.5;
  if Power > MaxPower.FinalValue then
      Power := MaxPower.FinalValue;

  // 1力量=1护甲
  Armor.IncreaseFromAssociate.DirectValue := Strength.FinalValue;

  // 10力量=1物理抗性
  PhysicsResistance.IncreaseFromAssociate.DirectValue := Strength.FinalValue * 0.1;
  // 10智力=1火焰伤害抗性
  FireResistance.IncreaseFromAssociate.DirectValue := Intelligence.FinalValue * 0.1;
  // 10智力=1冰冷伤害抗性
  ColdResistance.IncreaseFromAssociate.DirectValue := Intelligence.FinalValue * 0.1;
  // 10智力=1毒素伤害抗性
  PoisonResistance.IncreaseFromAssociate.DirectValue := Intelligence.FinalValue * 0.1;
  // 10智力=1秘法伤害抗性
  ArcaneResistance.IncreaseFromAssociate.DirectValue := Intelligence.FinalValue * 0.1;

  // 5点灵巧+1攻速
  AttackSpeed.IncreasePercentageFromAssociate.DirectValue := Dexterous.FinalValue * 0.2;
  // 10点灵巧+1%闪避几率
  if Dexterous.FinalValue * 0.1 > 50 then
      ChanceToDodge.IncreaseFromAssociate.DirectValue := 50
  else
      ChanceToDodge.IncreaseFromAssociate.DirectValue := Dexterous.FinalValue * 0.1;

  // 10点灵巧属性+1格挡几率，总共增加30%格挡几率
  if Dexterous.FinalValue * 0.1 > 10 then
      v := 10
  else
      v := Dexterous.FinalValue * 0.1;

  // 10点力量属性+1格挡几率，总共增加30%格挡几率
  if Strength.FinalValue * 0.1 > 10 then
      v := v + 10
  else
      v := v + Strength.FinalValue * 0.1;

  // 10点智力属性+1格挡几率，总共增加30%格挡几率
  if Intelligence.FinalValue * 0.1 > 10 then
      v := v + 10
  else
      v := v + Intelligence.FinalValue * 0.1;

  // 10点属性+1格挡几率，总共增加30%格挡几率
  ChanceToBlock.IncreaseFromAssociate.DirectValue := v;

  // 格挡成功后伤害值降低受力量属性影响
  FBlockSuccessDamageReduce.IncreaseFromAssociate.DirectValue := Strength.FinalValue;

  // 最大伤害受物理，火焰，冰冷，毒素，秘法伤害总和影响
  MaxDamage.IncreaseFromAssociate.DirectValue :=
    PhysicsDamage.FinalValue + FireDamage.FinalValue + ColdDamage.FinalValue + PoisonDamage.FinalValue + ArcaneDamage.FinalValue;

  // 最小伤害为最大伤害一半
  MinDamage.IncreaseFromAssociate.DirectValue := MaxDamage.IncreaseFromAssociate.DirectValue * 0.5;

  case PrimaryAttribute of
    paStrength:
      begin
        MinDamage.IncreasePercentageFromAssociate.DirectValue := Strength.FinalValue;
        MaxDamage.IncreasePercentageFromAssociate.DirectValue := Strength.FinalValue;
      end;
    paDexterous:
      begin
        MinDamage.IncreasePercentageFromAssociate.DirectValue := Dexterous.FinalValue;
        MaxDamage.IncreasePercentageFromAssociate.DirectValue := Dexterous.FinalValue;
      end;
    paIntelligence:
      begin
        MinDamage.IncreasePercentageFromAssociate.DirectValue := Intelligence.FinalValue;
        MaxDamage.IncreasePercentageFromAssociate.DirectValue := Intelligence.FinalValue;
      end;
  end;

end;

procedure TBioBaseData.Clear;
var
  i: Integer;
begin
  for i := 0 to FDataItemList.Count - 1 do
      DisposeObject(FDataItemList[i]);
  FDataItemList.Clear;

  FNMAutomatedManager.Clear;
  FNMList.Clear;
end;

function TBioBaseData.GetDataOfID(ID: TDataID): TDataItem;
begin
  case ID of
    diStrength: Result := Strength;
    diDexterous: Result := Dexterous;
    diIntelligence: Result := Intelligence;
    diMinDamage: Result := MinDamage;
    diMaxDamage: Result := MaxDamage;
    diPhysicsDamage: Result := PhysicsDamage;
    diFireDamage: Result := FireDamage;
    diColdDamage: Result := ColdDamage;
    diPoisonDamage: Result := PoisonDamage;
    diArcaneDamage: Result := ArcaneDamage;
    diAttackSpeed: Result := AttackSpeed;
    diChanceToDodge: Result := ChanceToDodge;
    diChanceToBlock: Result := ChanceToBlock;
    diBlockSuccessDamageReduce: Result := BlockSuccessDamageReduce;
    diBulletAccurate: Result := BulletAccurate;
    diReceiveExtraDamage: Result := ReceiveExtraDamage;
    diArmor: Result := Armor;
    diPhysicsResistance: Result := PhysicsResistance;
    diFireResistance: Result := FireResistance;
    diColdResistance: Result := ColdResistance;
    diPoisonResistance: Result := PoisonResistance;
    diArcaneResistance: Result := ArcaneResistance;
    diVitality: Result := Vitality;
    diMaxHP: Result := MaxHP;
    diHPRegeneration: Result := HPRegeneration;
    diMaxPower: Result := MaxPower;
    diPowerRegeneration: Result := PowerRegeneration;
    diMovementSpeed: Result := MovementSpeed;
    diCooldownReduct: Result := CooldownReduct;
    else Result := nil;
  end;
end;

function TBioBaseData.GetDMOfStyle(dItm: TDataItem; Style: TIncreaseDataPostStyle; SeedNumber: Variant): TNumberModule;
begin
  Result := nil;
  if dItm = nil then
      Exit;
  case Style of
    dipsValue: Result := dItm.Value;

    dipsSpell: if SeedNumber > 0 then
          Result := dItm.IncreaseFromSpell
      else
          Result := dItm.ReduceFromSpell;

    dipsSpellPercentage: if SeedNumber > 0 then
          Result := dItm.IncreasePercentageFromSpell
      else
          Result := dItm.ReducePercentageFromSpell;

    dipsEquipment: if SeedNumber > 0 then
          Result := dItm.IncreaseFromEquipment
      else
          Result := dItm.ReduceFromEquipment;

    dipsEquipmentPercentage: if SeedNumber > 0 then
          Result := dItm.IncreasePercentageFromEquipment
      else
          Result := dItm.ReducePercentageFromEquipment;

    dipsAssociate: if SeedNumber > 0 then
          Result := dItm.IncreaseFromAssociate
      else
          Result := dItm.ReduceFromAssociate;
    dipsAssociatePercentage: if SeedNumber > 0 then
          Result := dItm.IncreasePercentageFromAssociate
      else
          Result := dItm.ReducePercentageFromAssociate;
  end;
end;

procedure TBioBaseData.DeletePostFlag(flag: TCoreClassPersistent);
begin
  FNMAutomatedManager.Delete(flag);
end;

// post automated overlap value
procedure TBioBaseData.PostOverlapData(ID: TDataID; Style: TIncreaseDataPostStyle; flag: TCoreClassPersistent; SeedNumber: Variant);
var
  dItem: TDataItem;
  DM: TNumberModule;
  v: Variant;
begin
  dItem := GetDataOfID(ID);
  DM := GetDMOfStyle(dItem, Style, SeedNumber);
  if v < 0 then
      v := 0 - v;
  if DM <> nil then
      FNMAutomatedManager.PostAutomatedProcess(npsInc, DM, flag, v, True, Integer(ID), 0);
end;

// post automated no overlap value
procedure TBioBaseData.PostData(ID: TDataID; Style: TIncreaseDataPostStyle;
  flag: TCoreClassPersistent; SeedNumber: Variant; TypeID: Integer; Priority: Cardinal);
var
  dItem: TDataItem;
  DM: TNumberModule;
  v: Variant;
begin
  dItem := GetDataOfID(ID);
  DM := GetDMOfStyle(dItem, Style, SeedNumber);
  if v < 0 then
      v := 0 - v;
  if DM <> nil then
      FNMAutomatedManager.PostAutomatedProcess(npsInc, DM, flag, v, False, TypeID, Priority);
end;

end.
