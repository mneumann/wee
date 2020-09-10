# Wee Web Framework

## Copyright and License

Copyright (c) 2004-2020 by Michael Neumann (mneumann@ntecs.de).

Released under the terms of the MIT license.

## Introduction

Wee is a light-weight, very high-level and modern web-framework that makes
*W*eb *e*ngineering *e*asy. It mainly inherits many ideas and features from
[Seaside][seaside], but was written from scratch without ever looking at the
Seaside (or any other) sources. All code was developed from ideas and lots of
discussions with Avi Bryant. 


## Features

### Reusable components

Wee has _real_ components, which are like widgets in a GUI. Once written, you
can use them everywhere. They are completely independent and do not interfere
with other components. Components encapsulate state, a view and actions. Of
course you can use an external model or use templates for rendering.

### Backtracking

See the _What is backtracking?_ section below. In short, backtracking lets the
browser's back and forward-button play well together with your application.

### Clean and concise

Wee is well thought out, is written in *and* supports clean and concise code.
Furthermore I think most parts are now very well documented.

### Templating-independent 

Wee does not depend on a special templating-engine. You can use a different
templating engine for each component if you want. 

### Powerful programmatic HTML generation 

Wee ships with an easy to use and very powerful programmatic HTML-generation
library. For example you can create a select list easily with this piece of
code:

```ruby
# select an object from these items
items = [1, 2, 3, 4]

# the labels shown to the user
labels = items.map {|i| i.to_s}

# render it
r.select_list(items).labels(labels).callback {|choosen| p choosen}

# render a multi-select list, with objects 2 and 4 selected
r.select_list(items).multi.labels(labels).selected([2,4])
```

The callback is called with the selected objects from the _items_ array.  Items
can be any object, even whole components:

```ruby
labels = ["msg1", "msg2"]
items = labels.collect {|m| MessageBox.new(m)}
r.select_list(items).labels(labels).callback {|choosen| call choosen.first} 
```

## Observations and Limitations

* Components are thread-safe by nature as a fresh components-tree is created
  for each session and requests inside a session are serialized.

## What is backtracking?

If you want, you can make the back-button of your browser work correctly
together with your web-application. Imagine you have a simple counter
application, which shows the current count and two links _inc_ and _dec_ with
which you can increase or decrease the current count. Starting with an inital
count of 0 you increase the counter up to 8, then click three times the back
button of your browser (now displays 5). Finally you decrease by one and your
counter shows what you'd have expected: 4. In contrast, traditional web
applications would have shown 7, because the back button usually does not
trigger a HTTP request and as such the server-side state still has a value of 8
for the counter when the request to decrease comes in.

The solution to this problem is to take snapshots of the components state after
an action is performed and restoring the state before peforming actions. Each
action generates a new state, which is indicated by a so-called _page-id_
within the URL.

## Decorations

Decorations are used to modify the look and behaviour of a component without
modifying the components tree itself. A component can have more than one
decoration. Decorations are implemented as a linked list
(`Wee::Decoration#next` points to the next decoration), starting at
`Wee::Component#decoration`, which either points to the next decoration in the
chain, or to itself.

## The request/response cycle

The request/response cycle in Wee is actually split into two separate phases.

### Render Phase

The rendering phase is assumed to be side-effect free! So, you as a programmer
should take care to meet this assumption. Rendering is performed by method
`Wee::Component#render!`.

### Action Phase (Invoking Callbacks)

Possible sources for callbacks are links (anchors) and all kinds of
form-elements like submit buttons, input-fields etc. There are two different
kinds of callbacks:

* Input callbacks (input-fields)

* Action callbacks (anchor, submit-button)

The distinction between input and action callbacks is important, as action
callbacks might depend on values of input-fields being assigned to instance
variables of the controlling component. Hence, Wee first invokes all input
callbacks before any action callback is triggered. Callback processing is
performed by method `Wee::Component#process_callbacks`.

The result of the action phase is an updated components state. As such, a
snapshot is taken of the new state and stored under a new page-id. Then, a
redirect requests is sent back to the client, including this new page-id.  The
client automatically follows this redirect and triggers a render phase of the
new page.

[seaside]: http://seaside.st/
