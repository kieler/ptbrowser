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
package de.cau.cs.kieler.ptolemy.klighd.transformation

import com.google.inject.Inject
import de.cau.cs.kieler.ptolemy.klighd.PluginConstants
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.AnnotationExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.LabelExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.MarkerExtensions
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import org.eclipse.core.runtime.CoreException
import org.eclipse.core.runtime.IStatus
import org.eclipse.core.runtime.Status
import org.eclipse.elk.core.options.CoreOptions
import org.eclipse.emf.ecore.EObject
import org.ptolemy.moml.ClassType
import org.ptolemy.moml.EntityType
import ptolemy.actor.IOPort
import ptolemy.actor.TypedCompositeActor
import ptolemy.actor.parameters.ParameterPort
import ptolemy.kernel.CompositeEntity
import ptolemy.kernel.Entity
import ptolemy.kernel.util.Attribute
import ptolemy.kernel.util.NamedObj
import ptolemy.kernel.util.StringAttribute
import ptolemy.moml.MoMLParser
import ptolemy.moml.filter.BackwardCompatibility

import static de.cau.cs.kieler.ptolemy.klighd.transformation.util.TransformationConstants.*
import de.cau.cs.kieler.klighd.kgraph.KPort
import de.cau.cs.kieler.klighd.kgraph.util.KGraphUtil

/**
 * Provides an interface to the Ptolemy library to instantiate actors. This is used during the
 * transformation to get our hands at the list of ports defined for an actor.
 * 
 * @author cds
 * @author haf
 * @kieler.rating yellow 2012-06-14 KI-12 cmot, grh
 */
class PtolemyInterface {
    
    /** Accessing annotations. */
    @Inject extension AnnotationExtensions
    /** Marking nodes. */
    @Inject extension MarkerExtensions
    /** Labeling nodes and ports. */
    @Inject extension LabelExtensions
    
    
    /**
     * A cache mapping qualified class names of Ptolemy actors to their actual instances. If an actor
     * was already instantiated, there's no need to instantiate it again since that's quite a bit of
     * work.
     */
    static HashMap<String, Entity> entityCache = new HashMap<String, Entity>()
    
    
    /**
     * Tries to instantiate the given entity to return a list of its ports. The entity must either be
     * an {@code EntityType} or a {@code ClassType}. If the entity could not be instantiated, an empty
     * list is returned.
     * 
     * @param entity description of the entity.
     * @return list of ports which will be empty if the entity could not be instantiated.
     * @throws Exception if the instantiation fails.
     */
    def List<KPort> getPortsFromImplementation(EObject entity) {
        // Create an empty list of ports which we'll add to
        val result = new ArrayList<KPort>()
        
        // Try to instantiate the actor (this is where an exception might be thrown which is propagated
        // up to the calling method)
        var Entity ptActor = null
        ptActor = instantiatePtolemyEntity(entity)
        
        // Add its ports
        if (ptActor !== null) {
            var index = 0
            for (port : ptActor.portList) {
                if (port instanceof IOPort) {
                    val IOPort ptPort = port as IOPort
                    val KPort kPort = KGraphUtil::createInitializedPort()
                    
                    // Set the index
                    kPort.setProperty(CoreOptions::PORT_INDEX, index)
                    
                    // Set the name
                    kPort.name = ptPort.name
                    kPort.markAsPtolemyElement()
                    
                    // Turn attributes into properties
                    for (attribute : ptPort.attributeList) {
                        if (attribute instanceof Attribute) {
                            turnAttributeIntoAnnotation(kPort, attribute as Attribute)
                        }
                    }
                    
                    // Find out whether it is an input or an output port (or even both)
                    if (ptPort.input || kPort.hasAnnotation("input")
                        || kPort.hasAnnotation("inputoutput")) {
                        
                        kPort.markAsInputPort(true)
                    }
                    
                    if (ptPort.output || kPort.hasAnnotation("output")
                        || kPort.hasAnnotation("inputoutput")) {
                        
                        kPort.markAsOutputPort(true)
                    }
                    
                    // Remember if this is a multiport
                    if (ptPort.multiport) {
                        kPort.addAnnotation(IS_MULTIPORT)
                    }
                    
                    // Annotate with the port type (we currently distinguish two port types)
                    if (ptPort instanceof ParameterPort) {
                        kPort.addAnnotation(IS_PARAMETER_PORT)
                    } else {
                        kPort.addAnnotation(IS_IO_PORT)
                    }
                    
                    // Add the created port to our result list
                    result.add(kPort)
                }
                index = index + 1
            }
        }
        
        // Return the list of ports
        result
    }
    
    /**
     * Makes an annotation out of the given attribute and attaches it to the given object.
     * Recursively adds attributes of the attributes to the correspondingly created annotations.
     * 
     * @param element the KGraph element to annotate with the transformed attribute.
     * @param ptAttribute the attribute to turn into an annotation.
     */
    def private void turnAttributeIntoAnnotation(EObject element, Attribute ptAttribute) {
        val property = element.addAnnotation(ptAttribute.name, "", ptAttribute.className)
        
        // Check if we have a string attribute
        if (ptAttribute instanceof StringAttribute) {
            property.value = (ptAttribute as StringAttribute).valueAsString
        }
        
        // Recursively add further attributes
        for (attribute : ptAttribute.attributeList) {
            if (attribute instanceof Attribute) {
                turnAttributeIntoAnnotation(property, attribute as Attribute)
            }
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Actor Instantiation
    
    /**
     * Tries to instantiate the entity referenced by the given entity type.
     * 
     * @param ptEntity entity type describing the entity to instantiate.
     * @return the instantiated entity.
     * @throws Exception if the instantiation fails.
     */
    def dispatch Entity instantiatePtolemyEntity(EntityType ptEntity) {
        instantiatePtolemyEntityWithCache(ptEntity.class1, ptEntity.name)
    }
    
    /**
     * Tries to instantiate the entity referenced by the given class type.
     * 
     * @param ptClass class type describing the entity to instantiate.
     * @return the instantiated entity.
     * @throws Exception if the instantiation fails.
     */
    def dispatch Entity instantiatePtolemyEntity(ClassType ptClass) {
        instantiatePtolemyEntityWithCache(ptClass.^extends, ptClass.name)
    }
    
    /**
     * Tries to instantiate the entity referenced by the given class name.
     * 
     * @param className name of the class of the entity to instantiate.
     * @return the instantiated entity.
     * @throws Exception if the instantiation fails.
     */
    def dispatch Entity instantiatePtolemyEntity(String className) {
        instantiatePtolemyEntityWithCache(className, "anEntity")
    }
    
    /**
     * Instantiates the Ptolemy actor with the given class name. The entity name doesn't matter, but
     * makes errors make more sense.
     * 
     * @param className the fully qualified class name of the actor to instantiate.
     * @param entityName the actor's name in the model. Useful for error messages.
     * @return the instantiated entity.
     * @throws CoreException if the actor couldn't be instantiated.
     */
    def private Entity instantiatePtolemyEntityWithCache(String className, String entityName) {
        val cachedEntity = entityCache.get(className)
        
        if (cachedEntity === null) {
            // The entity is not already in the cache, so try to instantiate it
            try {
                if (className.equals("ptolemy.domains.modal.kernel.State")) {
                    val entity = instantiatePtolemyState(className, entityName)
                    entityCache.put(className, entity)
                    return entity
                } else {
                    val entity = instantiatePtolemyActor(className, entityName)
                    entityCache.put(className, entity)
                    return entity
                }
            } catch (Exception e) {
                // An exception occurred: wrap it
                throw new CoreException(new Status(
                    IStatus::WARNING,
                    PluginConstants::PLUGIN_ID,
                    "Unable to instantiate actor %1 (class '%2')."
                        .replace("%1", entityName)
                        .replace("%2", className),
                    e
                ))
            }
        } else {
            // The entity is already in the cache, so just return that
            cachedEntity
        }
    }
    
    /**
     * Instantiates a Ptolemy actor of the given class with the given name.
     * 
     * @param className the name of the actor's class.
     * @param entityName the name that should be used for the actor when instantiating it. This has no
     *                   influence on the functionality, but results in more readable error messages if
     *                   anything goes wrong.
     * @return the instantiated actor.
     * @throws Exception if the instantiation fails.
     */
    def private Entity instantiatePtolemyActor(String className, String entityName) {
        // Get our hands at Ptolemy's internal MoML parser
        MoMLParser::setMoMLFilters(BackwardCompatibility::allFilters())
        val parser = new MoMLParser()
        
        // We need to generate a basic MoML file with a valid parent entity and the actual actor entity
        // we want to instantiate
        val xml = '''
            <entity name="TopLevel" class="ptolemy.actor.TypedCompositeActor">
                <entity name="«entityName»" class="«className»" />
            </entity>
        '''
        
        // Parse XML
        val NamedObj parentElement = parser.parse(xml.toString())
        (parentElement as TypedCompositeActor).entityList().get(0) as Entity
    }
    
    /**
     * Instantiates a Ptolemy state entity of the given class with the given name.
     * 
     * @param className the name of the actor's class.
     * @param entityName the name that should be used for the actor when instantiating it. This has no
     *                   influence on the functionality, but results in more readable error messages if
     *                   anything goes wrong.
     * @return the instantiated actor.
     * @throws Exception if the instantiation fails.
     */
    def private Entity instantiatePtolemyState(String className, String entityName) {
        // Get our hands at Ptolemy's internal MoML parser
        MoMLParser::setMoMLFilters(BackwardCompatibility::allFilters())
        val parser = new MoMLParser()
        
        // We need to generate a basic MoML file with a valid parent entity and the actual actor entity
        // we want to instantiate
        val xml = '''
            <entity name="TopLevel" class="ptolemy.domains.modal.modal.ModalController">
                <entity name="«entityName»" class="«className»" />
            </entity>
        '''
        
        // Parse XML and return the first entity in the returned list. If the parser has a problem or
        // if the returned list is empty, an exception will be thrown which is then propagated up to
        // the calling method
        val NamedObj parentElement = parser.parse(xml.toString())
        (parentElement as CompositeEntity).entityList().get(0) as Entity
    }
}