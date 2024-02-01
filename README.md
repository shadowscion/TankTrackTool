# Description
With tanks being such a popular thing to build in gmod, it is sad indeed to know
that realistic tank tracks are nearly impossible. This tool aims to, mostly, solve
that issue. Please post pictures so I can add them to the images!

# Concept
 * Wheels are defined
 * A spline is generated around these wheels
 * Models are rendered around this spline
 * An animated scrolling texture is dynamically scaled to fit these models
 * Tank tracks!

# Features:
 * Easy to use; spawn, select wheels, edit with context menu, and go!
 * A lot of options so far, and probably more in the future.
 * 100% Clientside (apart from the networked editable options)
 * No more laggy `E2` tracks, or, god forbid, physical ones!

# Credits:
 * MrWhite; textures
 * DatAmazingCheese; textures
 * Metamist; icon
 * Waxx; server testing
 * Thebutheads; ideas
 * Karbine; ideas
 * dvd_video; wiremod api update and readme
 
# Use the [workshop version][ref-ws]!

# Wiremod API

|              Entity extensions               | Out | Description |
|:---------------------------------------------|:---:|:------------|
|![image][ref-e]:`tanktracktoolCopyValues`(![image][ref-e])|![image][ref-xxx]|Copies the track values from one entity to another|
|![image][ref-e]:`tanktracktoolGetLinkNames`(![image][ref-xxx])|![image][ref-r]|Returns an array containing the link names|
|![image][ref-e]:`tanktracktoolResetValues`(![image][ref-xxx])|![image][ref-xxx]|Resets the entity internal track values|
|![image][ref-e]:`tanktracktoolSetLinks`(![image][ref-t])|![image][ref-xxx]|Updates the entity links from the table passed|
|![image][ref-e]:`tanktracktoolSetValue`(![image][ref-s],![image][ref-...])|![image][ref-xxx]|Updates the values under the specified index|

|        General functions         | Out | Description |
|:---------------------------------|:---:|:------------|
|`tanktracktoolCanUseValue`(![image][ref-xxx])|![image][ref-n]|Checks the calm down whenever a value can be used|
|`tanktracktoolCreate`(![image][ref-n],![image][ref-s],![image][ref-s],![image][ref-v],![image][ref-a])|![image][ref-e]|Create an entity with given class by request|

[ref-a]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-a.png
[ref-b]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-b.png
[ref-c]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-c.png
[ref-e]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-e.png
[ref-xm2]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-xm2.png
[ref-m]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-m.png
[ref-xm4]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-xm4.png
[ref-n]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-n.png
[ref-q]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-q.png
[ref-r]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-r.png
[ref-s]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-s.png
[ref-t]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-t.png
[ref-xv2]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-xv2.png
[ref-v]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-v.png
[ref-xv4]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-xv4.png
[ref-xrd]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-xrd.png
[ref-xwl]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-xwl.png
[ref-xft]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-xft.png
[ref-xsc]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-xsc.png
[ref-xxx]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-xxx.png
[ref-...]: https://raw.githubusercontent.com/dvdvideo1234/ZeroBraineProjects/master/ExtractWireWiki/types/type-....png
