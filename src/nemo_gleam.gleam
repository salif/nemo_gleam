import actions
import argv
import install
import msgs

pub fn main() {
   let msg: fn(String) -> String = msgs.get_msg()
   case argv.load().arguments {
      ["new", ..rest] -> actions.run_new(rest, msg)
      ["actions", ..rest] -> actions.run(rest, msg)
      ["action", ..rest] -> actions.run_action(rest, msg)
      ["self-install", ..rest] -> install.run(rest)
      _ ->
         actions.alert(
            0,
            msg("Usage:")
               <> " gleam-action <COMMAND>"
               <> "\n\n"
               <> msg("Commands:")
               <> "\n  new\t\t"
               <> msg("Create a new project")
               <> "\n  actions\t\t"
               <> msg("Actions")
               <> "\n  action\t\t"
               <> msg("Action"),
         )
   }
}
