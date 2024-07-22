import aham
import locale

pub fn get_msg() {
   let msgs =
      aham.new_with_values()
      |> aham.auto_add_bundle(locale.get_locale(), [
         #("bg", "BG", [
            #(
               "Create a new project",
               "Създаване на нов проект",
            ),
            #("Name of the project", "Име на проекта"),
            #("Skip git", "Без git"),
            #("Skip github", "Без github"),
            #("Template", "Шаблон"),
            #("no", "не"),
            #("yes", "да"),
            #("Usage:", "Използване:"),
            #("Commands:", "Команди:"),
            #("Actions", "Действия"),
            #("Gleam Actions", "Gleam Действия"),
            #("Not supported yet", "Все още не се поддържа"),
            #("Invalid output: ", "Невалиден изход: "),
         ]),
      ])
   fn(str: String) -> String { aham.get(msgs, str) }
}
