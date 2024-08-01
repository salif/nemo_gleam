import actions
import aham
import argv
import locale
import msgs

pub fn main() {
   let msg: fn(String) -> String = fn(str: String) -> String {
      aham.auto_add_bundle(
         aham.new_with_values(),
         locale.get_locale(),
         msgs.all,
      )
      |> aham.get(str)
   }
   case argv.load().arguments {
      ["new", ..rest] -> actions.run_new(rest, msg)
      ["action", ..rest] -> actions.run_action(rest, msg)
      ["actions", ..rest] -> actions.run(rest, msg)
      ["list", ..rest] -> actions.run_actions_list(rest, msg)
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
               <> "\n  list\t\t"
               <> msg("Actions")
               <> "\n  action\t\t"
               <> msg("Action"),
         )
   }
}
