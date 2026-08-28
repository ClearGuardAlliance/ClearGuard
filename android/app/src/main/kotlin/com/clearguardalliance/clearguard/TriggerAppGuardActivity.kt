package com.clearguardalliance.clearguard

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.os.CountDownTimer
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class TriggerAppGuardActivity : Activity() {
    private var timer: CountDownTimer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
        )
        val mode = intent.getStringExtra(EXTRA_MODE) ?: MODE_PAUSE
        setContentView(if (mode == MODE_BLOCK) buildBlockLayout() else buildPauseLayout())
    }

    private fun buildBlockLayout(): LinearLayout {
        val root = baseLayout()
        val title = TextView(this).apply {
            text = "Fora do horário liberado"
            setTextColor(Color.WHITE)
            textSize = 22f
            gravity = Gravity.CENTER
        }
        val subtitle = TextView(this).apply {
            text = "Esse app fica bloqueado nesse horário pelo ClearGuard."
            setTextColor(Color.LTGRAY)
            textSize = 15f
            gravity = Gravity.CENTER
        }
        val closeButton = Button(this).apply {
            text = "Voltar para a tela inicial"
            setOnClickListener { goHome() }
        }
        root.addView(title)
        root.addView(subtitle, marginTop(16))
        root.addView(closeButton, marginTop(32))
        return root
    }

    private fun buildPauseLayout(): LinearLayout {
        val root = baseLayout()
        val title = TextView(this).apply {
            text = "Respira um pouco antes de continuar"
            setTextColor(Color.WHITE)
            textSize = 22f
            gravity = Gravity.CENTER
        }
        val countdown = TextView(this).apply {
            text = "$PAUSE_SECONDS"
            setTextColor(Color.WHITE)
            textSize = 40f
            gravity = Gravity.CENTER
        }
        val continueButton = Button(this).apply {
            text = "Continuar"
            isEnabled = false
            setOnClickListener { finish() }
        }
        val goHomeButton = Button(this).apply {
            text = "Voltar para a tela inicial"
            setOnClickListener { goHome() }
        }

        timer = object : CountDownTimer(PAUSE_SECONDS * 1000L, 1000L) {
            override fun onTick(millisUntilFinished: Long) {
                countdown.text = "${millisUntilFinished / 1000 + 1}"
            }

            override fun onFinish() {
                countdown.text = "Pronto"
                continueButton.isEnabled = true
            }
        }.start()

        root.addView(title)
        root.addView(countdown, marginTop(16))
        root.addView(continueButton, marginTop(24))
        root.addView(goHomeButton, marginTop(12))
        return root
    }

    private fun baseLayout(): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#1B2A28"))
            setPadding(48, 48, 48, 48)
        }
    }

    private fun marginTop(dp: Int): LinearLayout.LayoutParams {
        return LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        ).apply { topMargin = dp }
    }

    override fun onBackPressed() {
        goHome()
    }

    override fun onDestroy() {
        timer?.cancel()
        super.onDestroy()
    }

    private fun goHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_HOME)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(homeIntent)
        finishAndRemoveTask()
    }

    companion object {
        const val EXTRA_MODE = "mode"
        const val MODE_PAUSE = "pause"
        const val MODE_BLOCK = "block"
        private const val PAUSE_SECONDS = 15L
    }
}
