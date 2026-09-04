package com.zuhayrkabir.localmatchtrack.ui

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.View

object MatchTrackerTheme {
    val displayTypeface: Typeface = Typeface.create("sans-serif-condensed", Typeface.BOLD)
    val boldTypeface: Typeface = Typeface.create("sans-serif", Typeface.BOLD)
    val bodyTypeface: Typeface = Typeface.create("sans-serif", Typeface.NORMAL)

    object Colors {
        const val pitchBlack: Int = 0xFF080C09.toInt()
        const val panel: Int = 0xFF0B120E.toInt()
        const val panelRaised: Int = 0xFF0D1410.toInt()
        const val featuredTop: Int = 0xFF17331F.toInt()
        const val featuredBottom: Int = 0xFF090E0B.toInt()
        const val border: Int = 0xFF17231B.toInt()
        const val borderBright: Int = 0xFF1F3126.toInt()
        const val lime: Int = 0xFFC6F24E.toInt()
        const val grass: Int = 0xFF34A85C.toInt()
        const val grassDeep: Int = 0xFF17693A.toInt()
        const val muted: Int = 0xFF6F8877.toInt()
        const val textMuted: Int = 0xFF7E9686.toInt()
        const val textSoft: Int = 0xFF8FA697.toInt()
        const val offWhite: Int = 0xFFE8F3EA.toInt()
        const val danger: Int = 0xFFE24C4C.toInt()
        const val caution: Int = 0xFFF2C94C.toInt()
    }

    object Shapes {
        const val radiusSmall = 18f
        const val radiusMedium = 28f
        const val radiusLarge = 42f
    }

    fun roundedPanel(
        color: Int = Colors.panelRaised,
        strokeColor: Int = Colors.borderBright,
        radius: Float = Shapes.radiusMedium,
        strokeWidth: Int = 2,
    ): GradientDrawable =
        GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(color)
            cornerRadius = radius
            setStroke(strokeWidth, strokeColor)
        }

    fun featuredPanel(): GradientDrawable =
        GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            intArrayOf(Colors.featuredTop, Colors.featuredBottom),
        ).apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = Shapes.radiusLarge
            setStroke(2, Colors.borderBright)
        }

    fun primaryButton(): GradientDrawable =
        GradientDrawable(
            GradientDrawable.Orientation.LEFT_RIGHT,
            intArrayOf(Colors.lime, Color.rgb(145, 214, 72)),
        ).apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = 999f
        }

    fun secondaryButton(): GradientDrawable =
        roundedPanel(
            color = Colors.panel,
            strokeColor = Colors.grassDeep,
            radius = 999f,
        )

    fun View.applyCardShadow() {
        elevation = 8f
        translationZ = 2f
    }
}
