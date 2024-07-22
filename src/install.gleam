import argv
import envoy
import gleam/io
import gleam/result
import gleam/string
import simplifile

pub const dir_user_actions: String = "/.local/share/nemo/actions"

pub const dir_system_actions: String = "/usr/share/nemo/actions"

pub const dir_user_bin: String = "/.local/bin"

pub const dir_system_bin: String = "/usr/local/bin"

pub const dir_user_lib: String = "/.local/lib"

pub const dir_system_lib: String = "/usr/lib"

pub const arg_target_system: String = "system"

pub fn main() {
   let args: List(String) = argv.load().arguments
   let target_system: Bool = case args {
      ["system", ..] -> True
      _ -> False
   }
   let dir_dest: String = case args {
      ["system", "destdir", dest_dir, ..] | ["destdir", dest_dir, ..] ->
         dest_dir
      _ -> ""
   }

   let rezult: Result(Nil, String) =
      case dir_dest == "" && !target_system {
         True ->
            case envoy.get("HOME") {
               Ok(val) -> Ok(val)
               Error(_) -> Error("No HOME environment variable")
            }
         False -> Ok(dir_dest)
      }
      |> result.try(fn(hd: String) {
         let dir_actions: String = case target_system {
            True -> dir_system_actions
            _ -> dir_user_actions
         }
         let dir_bin: String = case target_system {
            True -> dir_system_bin
            _ -> dir_user_bin
         }
         let dir_lib: String = case target_system {
            True -> dir_system_lib
            _ -> dir_user_lib
         }
         case install_files(hd <> dir_actions, hd <> dir_bin, hd <> dir_lib) {
            Error(err) -> Error(string.inspect(err))
            Ok(_) -> Ok(Nil)
         }
      })

   case rezult {
      Error(err) -> {
         io.println_error("Error: " <> err)
      }
      Ok(_) -> io.println("Done!")
   }
}

fn install_files(
   dir_actions: String,
   dir_bin: String,
   dir_lib: String,
) -> Result(Nil, simplifile.FileError) {
   io.println("Installing actions: " <> dir_actions)
   simplifile.copy_file(
      "./actions/new_gleam_project.nemo_action",
      dir_actions <> "/new_gleam_project.nemo_action",
   )
   |> result.try(fn(_) {
      simplifile.copy_file(
         "./actions/gleam_actions.nemo_action",
         dir_actions <> "/gleam_actions.nemo_action",
      )
   })
   |> result.try(fn(_) {
      io.println("Installing scripts: " <> dir_bin)
      simplifile.copy_file(
         "./scripts/gleam-action.bash",
         dir_bin <> "/gleam-action",
      )
   })
   |> result.try(fn(_) {
      simplifile.set_permissions_octal(dir_bin <> "/gleam-action", 0o755)
   })
   |> result.try(fn(_) {
      io.println("Installing erlang-shipment: " <> dir_lib)
      let _ = simplifile.delete(dir_lib <> "/nemo_gleam")
      simplifile.copy_directory(
         "./build/erlang-shipment",
         dir_lib <> "/nemo_gleam",
      )
   })
}
