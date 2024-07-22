import alert
import gleam/list
import gleam/option.{Some}
import gu

pub fn run(args: List(String), msg: fn(String) -> String) -> Nil {
   case list.first(args) {
      Ok(path) -> action_new(path, msg)
      Error(Nil) -> alert.alert(0, msg("Usage:") <> " gleam-action new <PATH>")
   }
}

pub fn action_new(path: String, msg: fn(String) -> String) -> Nil {
   let output: Result(String, #(Int, String)) =
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
      |> gu.show(err: False)
   case output {
      Ok(out) -> {
         case gu.parse_list(out, "|") {
            [name, skip_git, skip_github, template] ->
               do_action_new(name, skip_git, skip_github, template, path, msg)
            _ -> alert.alert(1, msg("Invalid output: ") <> out)
         }
      }
      Error(_) -> Nil
   }
}

fn do_action_new(
   name: String,
   skip_git: String,
   skip_github: String,
   template: String,
   path: String,
   msg: fn(String) -> String,
) -> Nil {
   let out: Result(String, #(Int, String)) =
      ["new", "gleam"]
      |> gu.add_opt(Some(name), "name")
      |> gu.add_bool(skip_git == msg("yes"), "skip-git")
      |> gu.add_bool(skip_github == msg("yes"), "skip-github")
      |> gu.add_opt(Some(template), "template")
      |> gu.add_value(path <> "/" <> name)
      |> gu.show(err: True)
   case out {
      Ok(val) -> alert.alert(0, val)
      Error(err) -> alert.alert(err.0, err.1)
   }
}
