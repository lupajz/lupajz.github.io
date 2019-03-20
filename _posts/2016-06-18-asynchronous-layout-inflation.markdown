---
layout: post
title:  "Asynchronous layout inflation"
date:   2016-06-18 12:00:00 +0100
categories: android support-library
tags: android support-library
---
With recent release of [Android Support Library, revision 24](https://developer.android.com/topic/libraries/support-library/revisions.html) Google developers baked into v4 library a new helper class for asynchronous inflation of layouts.

## Enter AsyncLayoutInflater
You will find use for AsyncLayoutInflater in cases when you want to inflate parts of your applications UI lazily or as an response to users interactions. This helper class will allow your UI thread to continue being responsive while heavy inflation is being performed.

To use AsyncLayoutInflater you just have to create instance of it on your applications __UI thread__.

Consider this part of your Activity code (I’ll be using Kotlin syntax here):

```kotlin
val inflater = AsyncLayoutInflater(this)
```
And now with this instance you can inflate your layout file
```kotlin
inflater.inflate(resId: Int, parent: ViewGroup) 
```

As you can see the inflate function takes 3 parameter. First is your layout resource, second is optional view intended to be a parent of inflated hierarchy and third is a OnInflateFinishedListener, wich is a callback, that will be invoked once your layout has been inflated (in sample replaced by lambda function).

In comparsion the basic inflate function of LayoutInflater, that you would normaly use, takes boolean as a third parameter, that says whether the inflated hierarchy should be attached to the root parameter. As in our async version of inflate function there isn’t such a parameter you will most likely want to call in this way:

```kotlin
inflater.inflate(resId: Int, parent: ViewGroup) 
    { view, resid, parent -> parent.addView(view) }
```
## Drawbacks of using AsyncLayoutInflater
There are of course some drawbacks here:

- parents function _generateLayoutParams()_ has to be thread-safe
- all views being constructed must not create any Handlers or call Looper.myLooper() function
- no support for setting LayoutInflater.Factory nor LayoutInflater.Factory2
- no support for inflating layouts containing fragments
- If layout that we are trying to inflate in asynchronous way can not be constructed in this way, the inflation process will automaticaly fall back to inflation on UI thread.

### Small sample in Kotlin with use of Kotlin Android Extensions

MainActivity
```kotlin
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        loadFirst.setOnClickListener { 
           loadAsync(R.layout.async) { 
             second.text = "I am second TextView" 
           } 
        }
    }
}

fun MainActivity.loadAsync(@LayoutRes res: Int, 
                           action: View.() -> Unit) =
    AsyncLayoutInflater(this).inflate(res, frame) 
    { view, resid, parent ->
        with(parent) {
            addView(view)
            action(view)
        }
    }
```
activity_main.xml
```
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:id="@+id/frame"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="@dimen/activity_vertical_margin"
    android:orientation="vertical"
    tools:context="com.cartoon.player.MainActivity">

    <TextView
        android:id="@+id/loadFirst"
        android:layout_width="match_parent"
        android:layout_height="48dp"
        android:gravity="center"
        android:layout_marginBottom="16dp"
        android:text="Load f async"/>

</LinearLayout>
```

async.xml
```
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:orientation="vertical"
    android:layout_width="match_parent"
    android:layout_height="wrap_content">

    <TextView
        android:id="@+id/first"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginBottom="16dp"
        android:text="1"/>

    <TextView
        android:id="@+id/second"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginBottom="16dp"
        android:text="2"/>

</LinearLayout>
```

_Source: mostly source code for AsyncLayoutInflater class_
