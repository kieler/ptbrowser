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
package de.cau.cs.kieler.ptolemy.rcp;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.IEditorReference;
import org.eclipse.ui.PlatformUI;

import de.cau.cs.kieler.klighd.KlighdPlugin;
import de.cau.cs.kieler.klighd.KlighdPreferences;
import de.cau.cs.kieler.klighd.ZoomStyle;
import de.cau.cs.kieler.ptolemy.klighd.PtolemyEditorPart;

/**
 * @author uru
 * 
 */
public class ZoomToFitHandler extends AbstractHandler {

    /**
     * {@inheritDoc}
     */
    public Object execute(ExecutionEvent event) throws ExecutionException {

        final IPreferenceStore preferenceStore = KlighdPlugin.getDefault().getPreferenceStore();

        // get the toogle menu item
        Object trigger = event.getTrigger();
        Event triggerEvent = (Event) trigger;
        MenuItem item = (MenuItem) triggerEvent.widget;

        // determine its state
        boolean selection = item.getSelection();

        // set the preference value
        preferenceStore.setValue(KlighdPreferences.ZOOM_STYLE, (selection ? ZoomStyle.ZOOM_TO_FIT
                : ZoomStyle.NONE).name());

        try {
            for (IEditorReference ref : PlatformUI.getWorkbench().getActiveWorkbenchWindow()
                    .getActivePage().getEditorReferences()) {
                IEditorPart editor = ref.getEditor(false);
                if (editor instanceof PtolemyEditorPart) {
                    PtolemyEditorPart ptolemyEditor = (PtolemyEditorPart) editor;
                    ptolemyEditor.getViewer().getViewContext()
                            .setZoomStyle(selection ? ZoomStyle.ZOOM_TO_FIT : ZoomStyle.NONE);
                }
            }
        } catch (Exception e) {
            // silent
            // this is hacky anyway ...
        }

        return true;
    }
}
