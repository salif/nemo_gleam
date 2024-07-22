import gleam/option.{None, Some}
import gu

pub fn alert(alert_type: Int, text: String) -> Nil {
   let _ =
      gu.zenity
      |> gu.add_value(case alert_type {
         0 -> gu.type_info
         _ -> gu.type_error
      })
      |> gu.new_message_opts(
         text: Some(text),
         icon: None,
         no_wrap: False,
         no_markup: True,
         ellipsize: False,
      )
      |> gu.show(True)
   Nil
}
