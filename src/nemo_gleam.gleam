import actions
import aham
import argv
import locale
import msgs

const bin: String = "gleam-action"

pub fn main() -> Bool {
   let cx: actions.Cx =
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

fn parse_args(cx: actions.Cx, args: List(String)) -> Bool {
   case args {
      ["act", action, ..rest] -> actions.run_action(cx, action, rest)
      ["actions", ..rest] -> actions.run(cx, rest)
      ["list", ..rest] -> actions.run_actions_list(cx, rest)
      ["--gleam-cmd", gleam_cmd, ..rest] ->
         parse_args(actions.Cx(..cx, gleam_cmd: gleam_cmd), rest)
      _ ->
         actions.alert_usage(
            cx.msg("Usage"),
            cx.msg("Usage")
               <> ": "
               <> bin
               <> " <command>"
               <> "\n\n"
               <> cx.msg("Commands:")
               <> "\n  actions <path>\t\t"
               <> cx.msg("Actions (buttons)")
               <> "\n  list <path>\t\t\t"
               <> cx.msg("Actions (list)")
               <> "\n  act <action>\t\t"
               <> cx.msg("Action"),
         )
   }
}
