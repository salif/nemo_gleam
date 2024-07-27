import envoy
import gleam/io
import gleam/result
import gleam/string
import simplifile

pub const dir_actions_user: String = "/.local/share"

pub const dir_actions_system: String = "/usr/share"

pub const dir_bin_user: String = "/.local/bin"

pub const dir_bin_system: String = "/usr/bin"

pub const dir_lib_user: String = "/.local/lib"

pub const dir_lib_system: String = "/usr/lib"

pub const dir_licenses_system: String = "/usr/share/licenses"

pub const arg_target_system: String = "system"

// self-install system destdir "$DESTDIR"

pub fn run(args: List(String)) -> Bool {
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
      ife(
         string.is_empty(dir_dest) && !target_system,
         case envoy.get("HOME") {
            Ok(val) -> Ok(val)
            Error(_) -> Error("No HOME environment variable")
         },
         Ok(dir_dest),
      )
      |> result.try(fn(hd: String) {
         let dir_actions: String =
            ife(target_system, dir_actions_system, dir_actions_user)
         let dir_bin: String = ife(target_system, dir_bin_system, dir_bin_user)
         let dir_lib: String = ife(target_system, dir_lib_system, dir_lib_user)
         let dir_licenses: String =
            ife(target_system, dir_licenses_system, dir_lib_user)
         let res =
            install_files(
               hd <> dir_actions,
               hd <> dir_bin,
               hd <> dir_lib,
               hd <> dir_licenses,
            )
         case res {
            Error(err) -> Error(string.inspect(err))
            Ok(_) -> Ok(Nil)
         }
      })

   case rezult {
      Error(err) -> {
         io.println_error("Error: " <> err)
         False
      }
      Ok(_) -> {
         io.println("Done!")
         True
      }
   }
}

fn install_files(
   dir_actions: String,
   dir_bin: String,
   dir_lib: String,
   dir_licenses: String,
) -> Result(Nil, simplifile.FileError) {
   io.println("Installing actions: " <> dir_actions)
   simplifile.create_directory_all(dir_actions <> "/nemo/actions/")
   |> result.try(fn(_) {
      simplifile.create_directory_all(dir_actions <> "/kio/servicemenus")
   })
   |> result.try(fn(_) {
      simplifile.copy_file(
         "./actions/new_gleam_project.nemo_action",
         dir_actions <> "/nemo/actions/new_gleam_project.nemo_action",
      )
   })
   |> result.try(fn(_) {
      simplifile.copy_file(
         "./actions/gleam_actions.nemo_action",
         dir_actions <> "/nemo/actions/gleam_actions.nemo_action",
      )
   })
   |> result.try(fn(_) {
      simplifile.copy_file(
         "./actions/dolphin.desktop",
         dir_actions <> "/kio/servicemenus/dolphin_gleam_action.desktop",
      )
   })
   |> result.try(fn(_) {
      simplifile.set_permissions_octal(
         dir_actions <> "/kio/servicemenus/dolphin_gleam_action.desktop",
         0o755,
      )
   })
   |> result.try(fn(_) {
      io.println("Installing scripts: " <> dir_bin)
      simplifile.create_directory_all(dir_bin)
   })
   |> result.try(fn(_) {
      simplifile.copy_file(
         "./scripts/gleam-action.sh",
         dir_bin <> "/gleam-action",
      )
   })
   |> result.try(fn(_) {
      simplifile.set_permissions_octal(dir_bin <> "/gleam-action", 0o755)
   })
   |> result.try(fn(_) {
      io.println("Installing erlang-shipment: " <> dir_lib)
      simplifile.create_directory_all(dir_lib)
   })
   |> result.try(fn(_) {
      let _ = simplifile.delete(dir_lib <> "/nemo_gleam")
      simplifile.copy_directory(
         "./build/erlang-shipment",
         dir_lib <> "/nemo_gleam",
      )
   })
   |> result.try(fn(_) {
      simplifile.create_directory_all(dir_licenses <> "/nemo_gleam")
   })
   |> result.try(fn(_) {
      simplifile.copy_file("./LICENSE", dir_licenses <> "/nemo_gleam/LICENSE")
   })
}

fn ife(a: Bool, if_true: a, if_false: a) -> a {
   case a {
      True -> if_true
      False -> if_false
   }
}
