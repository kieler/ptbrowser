/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2012 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.ptolemy.klighd.transformation.extensions

import de.cau.cs.kieler.ptolemy.klighd.PtolemyProperties
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.ptolemy.moml.ClassType
import org.ptolemy.moml.EntityType
import org.ptolemy.moml.MomlFactory
import org.ptolemy.moml.PropertyType
import de.cau.cs.kieler.klighd.kgraph.KGraphElement

/**
 * Utility methods regarding annotations used by the Ptolemy to KGraph transformation.
 * 
 * @author cds
 * @kieler.rating yellow 2012-07-10 KI-15 cmot, grh
 * 
 * @containsExtensions ptolemy
 */
class AnnotationExtensions {
    
    /** Factory used to create MoML model instances. */
    val momlFactory = MomlFactory::eINSTANCE
    
    
    /**
     * Returns the annotations of the given object.
     * This particular method looks for the property in the element's KShapeLayout.
     * 
     * @param element the object.
     * @return the annotations list or {@code null} if none was found.
     */
    def dispatch List<PropertyType> getAnnotations(KGraphElement element) {
        return element.getProperty(PtolemyProperties::PT_PROPERTIES)
    }
    
    /**
     * Returns the annotations of the given object.
     * This particular method looks for the properties directly attached to the element.
     * 
     * @param element the object.
     * @return the annotations list or {@code null} if none was found.
     */
    def dispatch List<PropertyType> getAnnotations(PropertyType element) {
        return element.property
    }
    
    /**
     * Returns the annotations of the given entity.
     * This particular method looks for the properties directly attached to the entity.
     * 
     * @param entity the entity.
     * @return the annotations list or {@code null} if none was found.
     */
    def dispatch List<PropertyType> getAnnotations(EntityType entity) {
        return entity.property
    }
    
    /**
     * Returns the annotations of the given entity.
     * This particular method looks for the properties directly attached to the entity.
     * 
     * @param entity the entity.
     * @return the annotations list or {@code null} if none was found.
     */
    def dispatch List<PropertyType> getAnnotations(ClassType entity) {
        return entity.property
    }
    
    /**
     * Returns the annotation with the given key from the given KGraph element.
     * 
     * @param element the KGraph element.
     * @param key the key of the annotation to return.
     * @return the annotation or {@code null} if there is none with the given key.
     */
    def PropertyType getAnnotation(EObject element, String key) {
        return getAnnotations(element).findFirst([p | p.name.equals(key)])
    }
    
    /**
     * Returns the value of the string annotation with the given key, if any.
     * 
     * @param element the element to fetch the annotation from.
     * @param key the annotation's key.
     * @return the annotation's value, if it exists, or the empty string if it doesn't.
     */
    def String getAnnotationValue(EObject element, String key) {
        return getAnnotation(element, key)?.value
    }
    
    /**
     * Returns the boolean value of the annotation with the given key, if any.
     * 
     * @param element the element to fetch the annotation from.
     * @param key the annotation's key.
     * @return {@code true} if the annotation exists and is true, {@code false} otherwise.
     */
    def boolean getAnnotationBooleanValue(EObject element, String key) {
        val annotation = getAnnotation(element, key)
        
        if (annotation === null) {
            return false
        } else {
            return annotation.value.equals("true")
        }
    }
    
    /**
     * Checks if the given KGraph element has a Ptolemy annotation of the given key. This method queries
     * the shape layout of the given element.
     * 
     * @param element the KGraph element.
     * @param key key of the annotation to look for.
     * @return {@code true} if such an annotation exists, {@code false} otherwise.
     */
    def boolean hasAnnotation(EObject element, String key) {
        return getAnnotation(element, key) !== null
    }
    
    /**
     * Adds an annotation with the given key to the given KGraph element, if no annotation with that
     * key already exists.
     * 
     * @param element the KGraph element.
     * @param key the annotation's key.
     * @return the created property.
     */
    def PropertyType addAnnotation(EObject element, String key) {
        if (!hasAnnotation(element, key)) {
            val property = momlFactory.createPropertyType()
            property.name = key
            
            element.annotations.add(property);
            
            return property;
        } else {
            element.getAnnotation(key)
        }
    }

    /**
     * Adds an annotation with the given key and value to the given KGraph element, if no annotation
     * with that key already exists.
     * 
     * @param element the KGraph element.
     * @param key the annotation's key.
     * @param value the annotation's value.
     * @return the created property.
     */
    def PropertyType addAnnotation(EObject element, String key, String value) {
        if (!hasAnnotation(element, key)) {
            val property = momlFactory.createPropertyType()
            property.name = key
            property.value = value
            
            element.annotations.add(property);
            
            return property;
        } else {
            element.getAnnotation(key)
        }
    }

    /**
     * Adds an annotation with the given key, type, and value to the given KGraph element, if no
     * annotation with that key already exists.
     * 
     * @param element the KGraph element.
     * @param key the annotation's key.
     * @param type the annotation's tyape.
     * @param value the annotation's value.
     * @return the created property.
     */
    def PropertyType addAnnotation(EObject element, String key, String value, String type) {
        if (!hasAnnotation(element, key)) {
            val property = momlFactory.createPropertyType()
            property.name = key
            property.value = value
            property.setClass(type)
            
            element.annotations.add(property);
            
            return property;
        } else {
            element.getAnnotation(key)
        }
    }
    
    /**
     * Removes the annotation with the given key, if any exists, from the given KGraph element.
     * 
     * @param element the KGraph element.
     * @param key the annotation's key.
     */
    def void removeAnnotation(EObject element, String key) {
        val annotations = getAnnotations(element)
        val annotation = getAnnotation(element, key)
        if (annotation !== null) {
            annotations.remove(annotation);
        }
    }
    
}
