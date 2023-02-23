extends Node

var save_name = "user://CirnoSnowglideSave.save"
func save_game():
    var saved_game = File.new()
    saved_game.open(save_name, File.WRITE)
    var savedata = Manager.records.duplicate(true)
    saved_game.store_string(to_json(savedata))
    saved_game.close()

func load_exists():
    return File.new().file_exists(save_name)

func load_game():
    var saved_game = File.new()
    if not saved_game.file_exists(save_name):
        return null
    saved_game.open(save_name, File.READ)
    var persisted_data = parse_json(saved_game.get_as_text())
    saved_game.close()
    return persisted_data
    
