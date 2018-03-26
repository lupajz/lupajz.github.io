import kotlinx.interop.wasm.dom.*
import kotlinx.wasm.jsinterop.*

fun main(args: Array<String>) {
    println("Hello Kotlin/Native!")

    val content = document.getElementById("content")
    val button  = document.getElementById("random_button")

    button.setter("onclick") {
        content
        println("Clicked")
    }


}