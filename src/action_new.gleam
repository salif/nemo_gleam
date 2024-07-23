import do_action
import gleam/list
import gleam/option.{Some}
import gu

pub fn run(args: List(String), msg: fn(String) -> String) -> Nil {
   case list.first(args) {
      Ok(path) -> action_new(path, msg)
      Error(Nil) ->
         do_action.alert(0, msg("Usage:") <> " gleam-action new <PATH>")
   }
}

pub fn action_new(path: String, msg: fn(String) -> String) -> Nil {
   let out: gu.GuResult =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Create a new project"))
      |> gu.add_entry(msg("Name of the project"))
      |> gu.add_combo_and_values(msg("Skip git"), values: [
         msg("no"),
         msg("yes"),
      ])
      |> gu.add_combo_and_values(msg("Skip github"), values: [
         msg("no"),
         msg("yes"),
      ])
      |> gu.add_combo_and_values(msg("Template"), values: ["lib"])
      |> gu.set_separator("|")
      |> gu.show_in(path, err: False)
   case out {
      Ok(out) -> {
         case gu.parse_list(out, "|") {
            [name, skip_git, skip_github, template] ->
               do_action.do_action(
                  ["new", "gleam"]
                     |> gu.add_opt(Some(name), "name")
                     |> gu.add_bool(skip_git == msg("yes"), "skip-git")
                     |> gu.add_bool(skip_github == msg("yes"), "skip-github")
                     |> gu.add_opt(Some(template), "template")
                     |> gu.add_value(path <> "/" <> name),
                  path,
               )
            _ -> do_action.alert(1, msg("Invalid output: ") <> out)
         }
      }
      Error(_) -> Nil
   }
}
