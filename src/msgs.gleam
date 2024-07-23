import aham
import locale

pub fn get_msg() -> fn(String) -> String {
   let msgs: aham.Aham =
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
            #("Close", "Затваряне"),
            #("no", "не"),
            #("yes", "да"),
            #("unset", "незададено"),
            #("Usage:", "Използване:"),
            #("Commands:", "Команди:"),
            #("Command", "Команда"),
            #("Actions", "Действия"),
            #("Gleam Actions", "Gleam Действия"),
            #("Not supported yet", "Все още не се поддържа"),
            #("Invalid output: ", "Невалиден изход: "),
            #(
               "Add new project dependencies",
               "Добавяне на нови зависимости",
            ),
            #(
               "The names of Hex packages to add",
               "Имената на Hex пакетите за добавяне",
            ),
            #(
               "Add the packages as dev-only dependencies",
               "Добавяне като само за разработчици",
            ),
            #("Format source code", "Форматиране на кода"),
            #("Files to format", "Файлове за форматиране"),
            #("Read source from STDIN", "Четене на кода от STDIN"),
            #(
               "Check if inputs are formatted without changing them",
               "Проверяване дали кодът е форматиран, без да го променя",
            ),
            #(
               "Remove project dependencies",
               "Премахване на зависимости",
            ),
            #(
               "The names of packages to remove",
               "Имената на пакетите за премахване",
            ),
            #("Run the project", "Стартиране на проекта"),
            #("Arguments", "Аргументи"),
            #("The platform to target", "Целева платформа"),
            #(
               "The runtime to target",
               "Целева среда за изпълнение",
            ),
            #("The module to run", "Модул за изпълняване"),
            #(
               "Run the project tests",
               "Стартиране на тестовете на проекта",
            ),
            #("Build the project", "Компилиране на проекта"),
            #(
               "Emit compile time warnings as errors",
               "Излъчване на предупрежденията като грешки",
            ),
            #(
               "Type check the project",
               "Проверка на типовете на проекта",
            ),
            #(
               "Work with dependency packages",
               "Работа с пакети на зависимости",
            ),
            #(
               "Render HTML documentation",
               "Рендериране на HTML документация",
            ),
            #(
               "Remove HTML docs from HexDocs",
               "Премахване на HTML документацията от HexDocs",
            ),
            #("The name of the package", "Името на пакета"),
            #(
               "The version of the docs to remove",
               "Версия на документация за премахване",
            ),
            #(
               "Publish the project to the Hex package manager",
               "Публикуване на проекта в Hex",
            ),
         ]),
      ])
   fn(str: String) -> String { aham.get(msgs, str) }
}
