import alert
import gleam/list
import gleam/option.{Some}
import gleam/string
import gu

pub fn run(args: List(String), msg: fn(String) -> String) -> Nil {
   case list.first(args) {
      Ok(path) -> actions(path, msg)
      Error(Nil) ->
         alert.alert(0, msg("Usage:") <> " gleam-action actions <PATH>")
   }
}

pub fn actions(path: string, msg: fn(String) -> String) -> Nil {
   let out: Result(String, #(Int, String)) =
      gu.zenity
      |> gu.new_question()
      |> gu.set_title(msg("Gleam Actions"))
      |> gu.new_message_opts(
         text: Some(msg("Commands:")),
         icon: Some("view-compact"),
         no_wrap: False,
         no_markup: True,
         ellipsize: False,
      )
      |> gu.new_question_opts(default_cancel: False, switch: True)
      |> gu.add_extra_button("update")
      |> gu.add_extra_button("test")
      |> gu.add_extra_button("shell")
      |> gu.add_extra_button("run")
      |> gu.add_extra_button("remove")
      |> gu.add_extra_button("publish")
      |> gu.add_extra_button("new")
      |> gu.add_extra_button("lsp")
      |> gu.add_extra_button("hex")
      |> gu.add_extra_button("help")
      |> gu.add_extra_button("format")
      |> gu.add_extra_button("fix")
      |> gu.add_extra_button("export")
      |> gu.add_extra_button("docs")
      |> gu.add_extra_button("deps")
      |> gu.add_extra_button("clean")
      |> gu.add_extra_button("check")
      |> gu.add_extra_button("build")
      |> gu.add_extra_button("add")
      |> gu.show(err: False)
   case out {
      Ok(out) | Error(#(_, out)) -> {
         case string.is_empty(out) {
            True -> Nil
            False -> {
               let cmd = gu.parse(out)
               case cmd {
                  "add" -> action_add(msg)
                  _ -> alert.alert(1, msg("Not supported yet"))
               }
            }
         }
      }
   }
}

fn action_add(msg: fn(String) -> String) -> Nil {
   let out: Result(String, #(Int, String)) =
      gu.zenity
      |> gu.new_forms()
      |> gu.set_text(msg("Add new project dependencies"))
      |> gu.add_entry(msg("The names of Hex packages to add"))
      |> gu.add_combo_and_values(
         msg(msg("Add the packages as dev-only dependencies")),
         values: [msg("no"), msg("yes")],
      )
      |> gu.set_separator("|")
      |> gu.show(err: False)
   case out {
      Ok(out) ->
         case gu.parse_list(out, "|") {
            [packages, dev] -> do_action_add(packages, dev, msg)
            _ -> alert.alert(1, msg("Invalid output: ") <> out)
         }
      Error(_) -> Nil
   }
}

fn do_action_add(
   packages: String,
   dev: String,
   msg: fn(String) -> String,
) -> Nil {
   let out: Result(String, #(Int, String)) =
      ["add", "gleam"]
      |> gu.add_bool(dev == msg("yes"), "dev")
      |> gu.add_value(packages)
      |> gu.show(err: True)
   case out {
      Ok(val) -> alert.alert(0, val)
      Error(err) -> alert.alert(err.0, err.1)
   }
}
