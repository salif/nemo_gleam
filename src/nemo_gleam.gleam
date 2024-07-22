import action_new
import actions
import alert
import argv
import msgs

pub fn main() {
   let msg: fn(String) -> String = msgs.get_msg()
   case argv.load().arguments {
      ["new", ..rest] -> action_new.run(rest, msg)
      ["actions", ..rest] -> actions.run(rest, msg)
      _ ->
         alert.alert(
            0,
            msg("Usage:")
               <> " gleam-action <COMMAND>"
               <> "\n\n"
               <> msg("Commands:")
               <> "\n"
               <> "  new\t\t"
               <> msg("Create a new project")
               <> "\n"
               <> "  actions\t\t"
               <> msg("Actions"),
         )
   }
}
