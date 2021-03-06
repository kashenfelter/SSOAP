setGeneric("toSOAP",
            function(obj, con = xmlOutputBuffer(header = ""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...) {
              tmp = standardGeneric("toSOAP")

#??? Is this the right thing to be doing?
   if(FALSE) {
              if(is(tmp, "XMLInternalNode") && !is.null(xmlParent(tmp)) && (is(con, "XMLInternalDocument") || is(con, "XMLInternalNode")))
                 addChildren(con, tmp)
   }
              
              tmp
            })




setMethod("toSOAP", c("POSIXt", type = "SOAPDate"),
              function(obj, con = xmlOutputBuffer(header=""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
                  format(obj, "%Y-%m-%d")) 

# ??? Time zone information.
setMethod("toSOAP", c("POSIXt", type = "SOAPDateTime"),
              function(obj, con = xmlOutputBuffer(header=""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
                  format(obj, "%Y-%m-%dT%H:%M:%S"))

setMethod("toSOAP", c("POSIXt", type = "SOAPTime"),
              function(obj, con = xmlOutputBuffer(header=""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
                  format(obj, "%h:%M:%S"))


setMethod("toSOAP", c("vector", type = "NULL"),
              function(obj, con = xmlOutputBuffer(header=""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
                   toSOAPArray(obj, con, type = type, literal = literal, ...))

setMethod("toSOAP", c("list", type = "NULL"),
          #
          # Is this ever used? If so, the first cat doesn't seem to make sense, i.e. leaves a <nodeName open.
          #
          #
function(obj, con = xmlOutputBuffer(header=""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
{
 if(length(names(obj)))
   return(toSOAPNamedContainer(obj, con, type, ...))
          
 if(length(obj) > 1) {
    # If we have named elements, then we need to do something with these rather than lose them
    # so we put them out as named elements, i.e. as a struct.
  if(!is.null(names(obj))) {
    for(i in names(obj)) {
      cat("<", i, file = con, sep="")
      writeTypes(obj[[i]])
      cat(obj[[i]])
    }
  } else {
    toSOAPArray(obj, con, type = type, literal = literal, ...)
  }
 } else {
    cat(obj, file=con)
 }

 invisible(TRUE)
})



setMethod("toSOAP", c("ANY", type = "SOAPType"),
function(obj, con = xmlOutputBuffer(header=""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
{
  if(literal) {
     for(i in names(getSlots(class(obj)))) {
       if(inherits(con, "connection")) {
          cat("<", i, ">", sep = "", file = con)
          p = con
       }
       else {
          p = newXMLNode(i)
          if(!is.null(con)) {
             addChildren(con, p)
          }
       }
       toSOAP(slot(obj, i), con = p, literal = literal)
       if(inherits(con, "connection"))       
          cat("</", i, ">\n", sep = "", file = con)       
     }
   } else {
      stop("No code yet for the toSOAP method for any object and SOAPType pair with literal = FALSE")
   }

   invisible(TRUE)
})



setMethod("toSOAP", c("ANY", type = "ClassDefinition"),
function(obj, con = xmlOutputBuffer(header=""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
{
  # literal = TRUE #XXX - xxxx

  if(literal) {
     for(i in names(getSlots(class(obj)))) {
       if(inherits(con, "connection")) {
          cat("<", i, ">", sep = "", file = con)
          p = con
       }
       else {
          p = newXMLNode(i)
          if(!is.null(con)) {
             addChildren(con, p)
          }
       }
       toSOAP(slot(obj, i), con = p, type = type@slotTypes[[i]], literal = literal)
       if(inherits(con, "connection"))       
          cat("</", i, ">\n", sep = "", file = con)       
     }
   } else {
      stop("No code yet for the toSOAP method for any object and ClassDefinition pair with literal = FALSE")
   }

   invisible(TRUE)
})


setGeneric("toSOAPArray", function(obj, con = stdout(), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
               {
                 if(length(names(obj))) 
                   return(toSOAPNamedContainer(obj, con))

                 standardGeneric("toSOAPArray")
               })

 # XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 #XXXXXXXXXXXXXXXXXXX
 # Looks like this is overridden below.
setMethod("toSOAP", c("vector", "XMLInternalElementNode", type = "missing"),
#
#  Taken from toSOAPArray method for "vector" (only) below.
#
function(obj, con = stdout(), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
{  
   if(length(obj) == 1 && (is.null(type) || is(type, "PrimitiveSOAPType"))) {
      tmp = newXMLTextNode(obj, parent = con)
      return(tmp)
   }

    lapply(obj, function(i) newXMLNode("item", i, parent = con))
 })

setMethod("toSOAPArray", c("vector"),
function(obj, con = stdout(), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
{
   if(length(obj) == 1 && (is.null(type) || is(type, "PrimitiveSOAPType"))) {
      tmp = newXMLTextNode(obj)
     # if(is(con, "XMLInternalDocument") || is(con, "XMLInternalNode"))
     #    addChildren(xmlRoot(con), tmp)
      return(tmp)
   }

   if(!is.null(type))
     elType = type@elType
   else
     elType = NULL

 #  for(i in obj) {
 #    newXMLNode("item", parent = con)
 #   }
 lapply(obj, function(i) newXMLNode("item", i))
   
})

setMethod("toSOAPArray", c("vector", "connection"),
function(obj, con = stdout(), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
{
   if(length(obj) == 1 && is.null(type)) {
      cat(obj, file = con)
      return(TRUE)     
   }

   newLine = "\r\n"
   newLine=""   

   if(!is.null(type))
     elType = type@elType
   else
     elType = NULL


    for(i in obj) {
if(TRUE) {
  tag = "item"
#  tag = gsub("^xsd:", "SOAP-ENC:", getSOAPType(i))
      cat("<", tag, " ", sep = "", file=con)
      writeTypes(i, con) # , type = elType)
      cat(">", newLine, sep="", file=con)
      cat(i, file=con)
      cat(newLine, "</", tag, ">", sep="", file=con)
} else {
  tmp = strsplit(getSOAPType(typeof(i)), ":")[[1]][2]
  cat("<", tmp, ">", sep="", file = con)
  cat(i, file=con)
  cat("</", tmp, ">", sep="", file=con)
}
    }
#   cat("</SOAP-ENC:Array>", file = con)
})


# toSOAPArray for XMLNode and Document object
tmp =
function(obj, con = stdout(), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...)
{

   if(length(names(obj))) {
     return(toSOAPNamedContainer(obj, con))
   }
  
   if(length(obj) == 1 && (is.null(type) || is(type, "PrimitiveSOAPType") ))
     return(newXMLTextNode(obj, parent = con))

   if(!is.null(type))
      elType = type@elType
   else
      elType = NULL

     # Not activated yet. We just pass the XMLInternalDocument
    # parent = if(is(con, "XMLInternalNode") || is(con, "XMLInternalDocument")) con else NULL
    parent = NULL

    lapply(obj,
           function(x) {
               # Since we typically don't have a parent node, we have to suppress the
               # warning about the xsi name space definition. And the problem is that
               # we don't even know which xsi namespace to use - 1999 or 2001
            newXMLNode("item",  x, attrs = writeTypes(x, con), parent = parent,
                        suppressNamespaceWarning = TRUE)
           })
}  

setMethod("toSOAPArray", c("vector", "XMLInternalDocument"), tmp)
setMethod("toSOAPArray", c("vector", "XMLInternalNode"), tmp)


setMethod("toSOAP", c(type = "ArrayType"),
              function(obj, con = xmlOutputBuffer(header = ""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...) {
                toSOAPArray(obj, con = con, type = type, literal = literal, ...)
              })


setMethod("toSOAP", c("vector", "connection", type = "PrimitiveSOAPType"),
              function(obj, con = xmlOutputBuffer(header=""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...) {
                val = type@toConverter(obj)
                if(length(val) > 1)
                  warning("Converting value to primitive SOAP type results in vector with more than one element. Ignoring remainder.")
                cat(val[1], file = con)
              }
)


                          #??? should this be XMLInternalElementNode ???
setMethod("toSOAP", c("vector", "XMLInternalDocument", type = "PrimitiveSOAPType"),
              function(obj, con = xmlOutputBuffer(header=""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...) {
                val = type@toConverter(obj)
                if(length(val) > 1)
                  warning("Converting value to primitive SOAP type results in vector with more than one element. Ignoring remainder.")
                newXMLTextNode(val[1], doc = con)
              }
)

setMethod("toSOAP", c("vector", "XMLInternalElementNode", type = "BasicSOAPType"),
              function(obj, con = xmlOutputBuffer(header = ""), type = NULL, literal = FALSE, elementFormQualified = FALSE, ...) {
                val = type@toConverter(obj)
                if(length(val) > 1)
                  warning("Converting value to primitive SOAP type results in vector with more than one element. Ignoring remainder.")
                newXMLTextNode(val[1], parent = con)  #??? what about the parent.
              }
)


setMethod("toSOAP", c("vector", type = "SOAPType"),
              function(obj, con = xmlOutputBuffer(header=""), type = NULL,  literal = FALSE, elementFormQualified = FALSE, ...) {
                toSOAPArray(obj, con, type = type, literal = literal, ...)
              })
