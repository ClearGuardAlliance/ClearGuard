package com.clearguardalliance.clearguard

import android.content.Context
import androidx.datastore.preferences.core.stringPreferencesKey
import io.flutter.plugins.sharedpreferences.sharedPreferencesDataStore
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking
import org.json.JSONObject

object NativeWebhookNotifier {
    private val executor = Executors.newSingleThreadExecutor()

    fun notify(context: Context, message: String) {
        executor.execute {
            val webhookUrl = readWebhookUrl(context) ?: return@execute
            if (webhookUrl.isEmpty()) return@execute
            postWebhook(webhookUrl, message)
        }
    }

    private fun postWebhook(webhookUrl: String, message: String) {
        try {
            val body = JSONObject().put("content", message).put("text", message)
            val connection = URL(webhookUrl).openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.connectTimeout = 5000
            connection.readTimeout = 5000
            connection.setRequestProperty("Content-Type", "application/json; charset=UTF-8")
            OutputStreamWriter(connection.outputStream).use { it.write(body.toString()) }
            connection.responseCode
            connection.disconnect()
        } catch (_: Exception) {
        }
    }

    private fun readWebhookUrl(context: Context): String? {
        return try {
            val key = stringPreferencesKey("flutter.accountability_webhook_url")
            runBlocking {
                context.sharedPreferencesDataStore.data.map { it[key] }.firstOrNull()
            }
        } catch (_: Exception) {
            null
        }
    }
}
