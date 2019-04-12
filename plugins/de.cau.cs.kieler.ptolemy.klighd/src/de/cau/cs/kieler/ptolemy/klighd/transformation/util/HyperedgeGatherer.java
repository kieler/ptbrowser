/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2013 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.ptolemy.klighd.transformation.util;

import java.util.List;
import java.util.Map;
import java.util.Set;

import org.eclipse.elk.core.options.CoreOptions;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Sets;

import de.cau.cs.kieler.klighd.kgraph.KEdge;
import de.cau.cs.kieler.klighd.kgraph.KNode;
import de.cau.cs.kieler.klighd.kgraph.KPort;


/**
 * Partitions relations from a root node into groups, of which each represents a hyperedge that connects
 * source nodes and ports to target nodes and ports. Sometimes, hyperedges can end up having only source
 * nodes and ports and no target nodes or ports.
 * 
 * @author cds
 * @kieler.rating proposed yellow cds 2015-02-23
 */
public final class HyperedgeGatherer {
    
    /** Root node that contains the relations. */
    private KNode root;
    /** List of hypernodes. */
    private List<Hyperedge> hyperedges;
    /** Mapping of each relation to its hyperedge for easy access. */
    private Map<KNode, Hyperedge> relationToHyperedge;
    
    
    /**
     * Creates a new instance for the given root node.
     * 
     * @param root the root node whose child relations to traverse.
     */
    public HyperedgeGatherer(final KNode root) {
        this.root = root;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    // Accessing Results
    
    /**
     * Returns the computed list of hyperedges. Can only sensibly be called once
     * {@link #gatherHyperedges()} has been called beforehand.
     * 
     * @return computed hyperedges.
     */
    public List<Hyperedge> getHyperedges() {
        return hyperedges;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    // Algorithm
    
    /**
     * Partitions relations from the root node into groups, each of which represents a hyperedge.
     */
    public void gatherHyperedges() {
        // Initialization
        hyperedges = Lists.newLinkedList();
        relationToHyperedge = Maps.newHashMap();
        
        // Iterate over the root's child nodes, looking for relations
        for (KNode node : root.getChildren()) {
            if (isRelation(node)) {
                handleRelation(node);
            }
        }
    }
    
    /**
     * Handles the given relation by iterating over its incident edges and adding and merging
     * hyperedges and shit.
     * 
     * @param relation the relation node.
     */
    private void handleRelation(final KNode relation) {
        Hyperedge hyperedge = relationToHyperedge.get(relation);
        
        // Create a new hyperedge if this relation doesn't already have one
        if (hyperedge == null) {
            hyperedge = new Hyperedge(relation);
            
            hyperedges.add(hyperedge);
            relationToHyperedge.put(relation, hyperedge);
        }
        
        // Iterate over the relation's edges, looking for connections to other relations
        for (KEdge edge : relation.getOutgoingEdges()) {
            if (isRelation(edge.getTarget())) {
                hyperedge = handleTwoRelations(relation, edge.getTarget());
            } else {
                // Standard connection to outside world
                if (edge.getTargetPort() == null) {
                    hyperedge.targetNodes.add(edge.getTarget());
                } else {
                    hyperedge.targetPorts.add(edge.getTargetPort());
                }
            }
        }
        
        for (KEdge edge : relation.getIncomingEdges()) {
            if (isRelation(edge.getSource())) {
                hyperedge = handleTwoRelations(relation, edge.getTarget());
            } else {
                // Standard connection to outside world
                if (edge.getSourcePort() == null) {
                    hyperedge.sourceNodes.add(edge.getSource());
                } else {
                    hyperedge.sourcePorts.add(edge.getSourcePort());
                }
            }
        }
    }
    
    /**
     * Checks if the two relations belong to the same hyperedge and, if not, merges the first hyperedge
     * into the second hyperedge. The first relation is assumed to already belong to a hyperedge.
     * 
     * @param relation1 the first relation, which already belongs to a hyperedge.
     * @param relation2 the first relation.
     * @return the hyperedge that both relations belong to after this method is done.
     */
    private Hyperedge handleTwoRelations(final KNode relation1, final KNode relation2) {
        Hyperedge he1 = relationToHyperedge.get(relation1);
        Hyperedge he2 = relationToHyperedge.get(relation2);

        // Check if the two relations belong to the same hyperedge
        if (he1 != he2) {
            // Does the second relation already belong to a hyperedge?
            if (he2 == null) {
                he1.relations.add(relation2);
                relationToHyperedge.put(relation2, he1);
                
                return he1;
            } else {
                // They don't; merge hyperedge 1 into hyperedge 2
                he2.relations.addAll(he1.relations);
                he2.sourceNodes.addAll(he1.sourceNodes);
                he2.sourcePorts.addAll(he1.sourcePorts);
                he2.targetNodes.addAll(he1.targetNodes);
                he2.targetPorts.addAll(he1.targetPorts);
                
                hyperedges.remove(he1);
                relationToHyperedge.put(relation1, he2);
                
                return he2;
            }
        } else {
            return he2;
        }
    }
    
    /**
     * Checks if a given node is a relation node or not.
     * 
     * @param node the node.
     * @return {@code true} if it is a relation.
     */
    private boolean isRelation(final KNode node) {
        return node.getProperty(CoreOptions.HYPERNODE);
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    // Class Hyperedge
    
    /**
     * A collection of relations, along with connections to regular nodes.
     * 
     * @author cds
     */
    public static class Hyperedge {
        /** Relations that belong to this hyperedge. */
        public List<KNode> relations = Lists.newLinkedList();
        /** Source nodes that directly connect to a relation in this hyperedge. */
        public Set<KNode> sourceNodes = Sets.newLinkedHashSet();
        /** Source ports that connect to a relation in this hyperedge. */
        public Set<KPort> sourcePorts = Sets.newLinkedHashSet();
        /** Target nodes that directly connect to a relation in this hyperedge. */
        public Set<KNode> targetNodes = Sets.newLinkedHashSet();
        /** Target ports that connect to a relation in this hyperedge. */
        public Set<KPort> targetPorts = Sets.newLinkedHashSet();
        
        
        /**
         * Creates a new hyperedge with the given relation.
         * 
         * @param relation the relation.
         */
        public Hyperedge(final KNode relation) {
            relations.add(relation);
        }
    }
    
}
