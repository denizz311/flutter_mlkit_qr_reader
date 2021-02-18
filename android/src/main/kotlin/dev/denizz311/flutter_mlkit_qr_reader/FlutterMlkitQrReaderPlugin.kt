package dev.denizz311.flutter_mlkit_qr_reader

import android.graphics.Bitmap
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.Size
import androidx.annotation.NonNull
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.google.android.gms.tasks.Task

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.google.mlkit.vision.barcode.Barcode
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.util.concurrent.Executor
import java.util.concurrent.Executors


class FlutterMlkitQrReaderPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var lifecycle: Lifecycle? = null

  private var lastDetectorId = 0
  private val detectors = mutableMapOf<Int, BarcodeScanner>()
  private val detectorBitmaps = mutableMapOf<Int, Bitmap>()
  private val detectorBitmapBuffers = mutableMapOf<Int, IntArray>()
  private val executors = mutableMapOf<Int, Executor>()

  private lateinit var binding: FlutterPlugin.FlutterPluginBinding

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_mlkit_qr_reader")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "prepareDetector" -> {
        val bitmapWidth = call.argument<Int>("bitmapWidth")!!
        val bitmapHeight = call.argument<Int>("bitmapHeight")!!

        val id = initDetector(
                bitmapSize = Size(bitmapWidth, bitmapHeight)
        )
        result.success(id)
      }
      "disposeDetector" -> {
        val id = call.argument<Int>("id")!!
        disposeDetector(id)
        result.success(null)
      }
      "processImage" -> {
        val id = call.argument<Int>("detectorId")!!
        val imageRgbBytes = call.argument<ByteArray>("rgbBytes")!!
        executors[id]!!.execute {
          val bitmap = detectorBitmaps[id]!!
          writeRgbByteArrayToBitmap(imageRgbBytes, detectorBitmapBuffers[id]!!, bitmap)
          val inputImage = InputImage.fromBitmap(bitmap, 0)
          detectors[id]!!.process(inputImage)
                  .addOnSuccessListener { barcodes ->
                    val results = barcodes.map {
                      it.rawValue
                    }
                    Handler(Looper.getMainLooper()).post {
                      result.success(results)
                    }
                  }
                  .addOnFailureListener {
                    Handler(Looper.getMainLooper()).post {
                      result.error("", it.localizedMessage, null)
                    }
                  }
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun initDetector(
          bitmapSize: Size
  ): Int {
    val id = lastDetectorId++

    val executor = Executors.newSingleThreadExecutor()
    executors[id] = executor

    val options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(
                    Barcode.FORMAT_QR_CODE)
            .build()

    val scanner = BarcodeScanning.getClient(options)
    lifecycle?.addObserver(scanner)

    detectors[id] = scanner
    detectorBitmaps[id] = Bitmap.createBitmap(bitmapSize.width, bitmapSize.height, Bitmap.Config.ARGB_8888)
    detectorBitmapBuffers[id] = IntArray(bitmapSize.width * bitmapSize.height)

    return id
  }

  private fun disposeDetector(id: Int) {
    detectors[id]?.let {
      lifecycle?.removeObserver(it)
      it.close()
    }
    detectors.remove(id)

    detectorBitmaps[id]?.recycle()
    detectorBitmaps.remove(id)

    detectorBitmapBuffers.remove(id)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}

private fun writeRgbByteArrayToBitmap(bytes: ByteArray, pixels: IntArray, bitmap: Bitmap) {
  val nrOfPixels: Int = bytes.size / 3 // Three bytes per pixel
  for (i in 0 until nrOfPixels) {
    val r = 0xFF and bytes[3 * i].toInt()
    val g = 0xFF and bytes[3 * i + 1].toInt()
    val b = 0xFF and bytes[3 * i + 2].toInt()

    pixels[i] = Color.rgb(r, g, b)
  }
  bitmap.setPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
}
