package app.piscatio

import androidx.core.content.FileProvider

/** Hands card images to Instagram (its own class, so it never clashes with plugins' providers). */
class StoriesFileProvider : FileProvider()
