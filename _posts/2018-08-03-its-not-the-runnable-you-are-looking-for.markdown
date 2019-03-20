---
layout: post
title:  "It’s not the Runnable you’re looking for"
date:   2018-08-03 12:00:00 +0100
image: /assets/kotlin-lighthouse.jpeg
categories: kotlin
tags: kotlin runnable android lambda
---
![Kotlin lighthouse](/assets/kotlin-lighthouse.jpeg)

So, I got burned by Kotlin recently. Don’t get me wrong here, I like it that I still find myself in situations where I think things should work, but they just don’t.

Let me describe the problem here. My colleague asked if I know how one could debounce _LiveData_ emissions, similar to behaviour of [debounce operator of RxJava](http://reactivex.io/documentation/operators/debounce.html), with a help of _MediatorLiveData_ and some simple code, that just always reschedules message send to UI thread, I tried to implement it like this:

```kotlin
val runnable = {
 mediatorLiveData.value = source.value
}

mediatorLiveData.addSource(source) { newElement -> 
 handler.removeCallbacks(runnable)
 handler.postDelayed(runnable, delay)
}
```

Seems good, code complies without any errors or warnings. But the result is nowhere near what one would expect, as the queued _Runnables_ are not being dequeued and will always get executed, which is not in our desire, but rather have the _Runnable_ execute only after give time if no new element was emitted by the source _LiveData_.
At first glance the code seems correct so the obvious step should be to take a look at decompiled bytecode using awesome Intellij tooling (Tools -> Kotlin -> Show Kotlin Bytecode -> Decompile):

```kotlin
class DataKt$debounce$$inlined$also$lambda$1$1 implements Runnable {
   // $FF: synthetic field
   private final Function0 function;

   Livedata2Kt$debounce$$inlined$also$lambda$1$1(Function0 var1) {
      this.function = var1;
   }

   // $FF: synthetic method
   public final void run() { ... }
}
// $FF: synthetic field
final Function0 $runnable;
public final void onChanged(@Nullable Object it) {
  Handler var10000 = this.$handler;
  Object var10001 = this.$runnable;
  Object var2;
  if (this.$runnable != null) {
    var2 = var10001;
    var10001 = new DataKt$debounce$$inlined$also$lambda$1$1((Function0)var2);
  }

  var10000.removeCallbacks((Runnable)var10001);
  var10000 = this.$handler;
  var10001 = this.$runnable;
  if (this.$runnable != null) {
    var2 = var10001;
    var10001 = new DataKt$debounce$$inlined$also$lambda$1$2((Function0)var2);
  }

  var10000.postDelayed((Runnable)var10001, this.$delay$inlined);
}
```

The shortened example shows what is really happening. The important part is that since both ``removeCallback`` and ``postDelayed`` methods are expecting first parameter to be of type _Runnable_ Kotlin compiler wraps the lambda function into class that implements the _Runnable_ contract and always creates a new instance of the wrapper class, which results in no _Runnable_ being dequeued.

The solution to this problem is simple. We just have to be explicit towards compiler about what type of callback are we going to be passing, so a simple change like:
```kotlin
val runnable = Runnable {
  mediatorLiveData.value = source.value
}
```
which will result into correctly generated code:
```kotlin
// $FF: synthetic field
final Runnable $runnable;
public final void onChanged(@Nullable Object it) {
   this.$handler.removeCallbacks(this.$runnable);
   this.$handler.postDelayed(this.$runnable, this.$delay$inlined);
}
```
which results in expected code.

__TL;DR__ of the story is to be explicit about types of anonymous callbacks when using Kotlin with Java interop.