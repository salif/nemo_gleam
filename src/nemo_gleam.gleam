import actions
import aham
import argv
import locale
import msgs

pub fn main() {
   let cx =
      actions.Cx(
         msg: fn(str: String) -> String {
            aham.auto_add_bundle(
               aham.new_with_values(),
               locale.get_locale(),
               msgs.all,
            )
            |> aham.get(str)
         },
         path: ".",
         gleam_cmd: "gleam",
         do_log: True,
      )
   parse_args(cx, argv.load().arguments)
}

fn parse_args(cx: actions.Cx, args: List(String)) {
   case args {
      ["new", ..rest] -> actions.run_new(cx, rest)
      ["action", ..rest] -> actions.run_action(cx, rest)
      ["actions", ..rest] -> actions.run(cx, rest)
      ["list", ..rest] -> actions.run_actions_list(cx, rest)
      ["--gleam-cmd", gleam_cmd, ..rest] ->
         parse_args(actions.Cx(..cx, gleam_cmd: gleam_cmd), rest)
      _ ->
         actions.alert(
            0,
            cx.msg("Usage:")
               <> " gleam-action <COMMAND>"
               <> "\n\n"
               <> cx.msg("Commands:")
               <> "\n  new\t\t"
               <> cx.msg("Create a new project")
               <> "\n  actions\t\t"
               <> cx.msg("Actions (buttons)")
               <> "\n  list\t\t"
               <> cx.msg("Actions (list)")
               <> "\n  action\t\t"
               <> cx.msg("Action"),
         )
   }
}
