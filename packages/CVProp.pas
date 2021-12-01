unit CVProp;

interface

Uses
  System.Classes,
  System.SyncObjs,
  DesignEditors,
  DesignIntf,
  CVClass;

Type
  TSourceProperty = class(TComponentProperty)
  private
    FInstance: TPersistent;
  protected
    function GetInstance: TPersistent; virtual;
  public
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure GetProperties(Proc: TGetPropProc); override;
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
    procedure Initialize; override;
    property Instance: TPersistent read GetInstance;
  end;

implementation

Uses
  System.SysUtils,
  System.TypInfo;

{ TSourceProperty }

function TSourceProperty.GetInstance: TPersistent;
var
  LInstance: TPersistent;
  LPersistentPropertyName: string;
begin
  if not Assigned(FInstance) then
  begin
    LInstance               := GetComponent(0);
    LPersistentPropertyName := GetName;
    if IsPublishedProp(LInstance, LPersistentPropertyName) then
    begin
      FInstance := TPersistent(GetObjectProp(LInstance, LPersistentPropertyName));
    end;
  end;
  Result := FInstance;
end;

procedure TSourceProperty.GetProperties(Proc: TGetPropProc);
begin
  inherited;
end;

procedure TSourceProperty.Initialize;
var
  LInstance: TPersistent;
  LPersistentPropertyName: string;
begin
  inherited Initialize;
  LInstance               := Instance;
  LPersistentPropertyName := GetName;
  if LInstance is TComponent then
  begin
    if (TComponent(LInstance).Name = '') and (TComponent(LInstance).Name <> LPersistentPropertyName) then
    begin
      TComponent(LInstance).Name := LPersistentPropertyName;
    end;
  end
  else if LInstance is TCVCustomSource then
  begin
    if (TCVCustomSource(LInstance).Name = '') and (TCVCustomSource(LInstance).Name <> LPersistentPropertyName) then
    begin
      TCVCustomSource(LInstance).Name := LPersistentPropertyName;
    end;
  end;
end;

function TSourceProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes;
  Result := Result - [paReadOnly] + [paValueList, paSortList, paRevertable, paSubProperties, paVolatileSubProperties];
end;

function TSourceProperty.GetValue: string;
begin
  Result := GetRegisteredCaptureSource.GetNameByClass(TCVCaptureSource(GetOrdValue).ClassType);
end;

procedure TSourceProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  rIO: TRegisteredCaptureSource;
begin
  rIO   := GetRegisteredCaptureSource;
  for I := 0 to rIO.Count - 1 do
    Proc(rIO[I]);
end;

procedure TSourceProperty.SetValue(const Value: string);
Var
  APropertiesClass: TCVSourceTypeClass;
  I: Integer;
  AIntf: ICVEditorPropertiesContainer;
begin
  APropertiesClass := GetRegisteredCaptureSource.FindByName(Value);
  if APropertiesClass = nil then
    APropertiesClass := TCVSourceTypeClass(GetRegisteredCaptureSource.Objects[0]);

  for I := 0 to PropCount - 1 do
    if Supports(GetComponent(I), ICVEditorPropertiesContainer, AIntf) then
      AIntf.SetPropertiesClass(APropertiesClass);

  Modified;
end;

initialization

RegisterPropertyEditor(TypeInfo(TCVCustomSource), TCVCaptureSource, 'SourceType', TSourceProperty);

UnlistPublishedProperty(TCVCustomSource, 'Name');
UnlistPublishedProperty(TCVCaptureSource, 'SourceTypeClassName');

end.
