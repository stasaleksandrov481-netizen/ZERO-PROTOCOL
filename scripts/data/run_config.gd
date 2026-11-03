class_name RunConfig
extends Resource
## Future menu-to-battle payload. No launch operation or pretend session exists yet.

@export var atlant: AtlantDefinition
@export var mission: MissionDefinition
@export var weapons: Array[WeaponDefinition] = []
@export var modules: Array[ModuleDefinition] = []
@export var input: InputSchemeSettings

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if atlant == null or atlant.visual_scene == null: errors.append("Нет готовой сцены Атланта.")
	if mission == null or not mission.can_launch(): errors.append("Нет доступной миссии.")
	if input == null: errors.append("Не выбрана конфигурация управления.")
	return errors
