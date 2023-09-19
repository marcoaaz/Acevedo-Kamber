// Written in QuPath 0.2.0-m11
def newClass = getPathClass("Vein3")   // Your new class here
def aaa = getPathClass("CPX")

getAnnotationObjects().each { annotation ->
    if (annotation.getPathClass().equals(aaa))
        annotation.setPathClass(newClass)
}

fireHierarchyUpdate() // If you want to update the count in the Annotation pane

print "Done!"