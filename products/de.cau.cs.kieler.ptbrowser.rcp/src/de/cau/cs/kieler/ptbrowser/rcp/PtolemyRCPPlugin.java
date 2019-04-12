package de.cau.cs.kieler.ptbrowser.rcp;

import java.lang.reflect.Field;

import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Status;
import org.eclipse.jface.action.IContributionItem;
import org.eclipse.jface.action.MenuManager;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.ui.IStartup;
import org.eclipse.ui.IWorkbenchPage;
import org.eclipse.ui.IWorkbenchWindow;
import org.eclipse.ui.PlatformUI;
import org.eclipse.ui.internal.ActionSetContributionItem;
import org.eclipse.ui.internal.PluginActionContributionItem;
import org.eclipse.ui.internal.WorkbenchWindow;
import org.eclipse.ui.internal.commands.CommandStateProxy;
import org.eclipse.ui.internal.ide.actions.OpenLocalFileAction;
import org.eclipse.ui.plugin.AbstractUIPlugin;
import org.eclipse.ui.statushandlers.StatusManager;
import org.osgi.framework.BundleContext;

import com.google.common.base.Strings;
import com.google.common.collect.ImmutableSet;

import de.cau.cs.kieler.klighd.KlighdPlugin;
import de.cau.cs.kieler.klighd.KlighdPreferences;
import de.cau.cs.kieler.klighd.ZoomStyle;

/**
 * The activator class controls the plug-in life cycle
 */
@SuppressWarnings("restriction")
public class PtolemyRCPPlugin extends AbstractUIPlugin implements IStartup {

    // The plug-in ID
    public static final String PLUGIN_ID = "de.cau.cs.kieler.ptolemy.rcp"; //$NON-NLS-1$

    // The shared instance
    private static PtolemyRCPPlugin plugin;

    private static final String OPEN_FILE = "org.eclipse.ui.openLocalFile";

    private static final String STATUS_BAR_CLASS = "org.eclipse.jface.action.StatusLine";
    
    private static final String ZOOM_TO_FIT = "de.cau.cs.kieler.ptolemy.rcp.zoomToFit";

    /** a list with all accepted menu contributions. */
    final ImmutableSet<String> acceptedMenuContribs = ImmutableSet.of(OPEN_FILE, "quit",
            "reopenEditors", "mru", "null", "quit", "fileEnd", "org.eclipse.ui.file.exit",
            "de.cau.cs.kieler.ptolemy.rcp.view", ZOOM_TO_FIT);

    /**
     * The constructor
     */
    public PtolemyRCPPlugin() {
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.ui.plugin.AbstractUIPlugin#start(org.osgi.framework.BundleContext)
     */
    public void start(BundleContext context) throws Exception {
        super.start(context);
        plugin = this;
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.ui.plugin.AbstractUIPlugin#stop(org.osgi.framework.BundleContext)
     */
    public void stop(BundleContext context) throws Exception {
        plugin = null;
        super.stop(context);
    }

    /**
     * Returns the shared instance
     * 
     * @return the shared instance
     */
    public static PtolemyRCPPlugin getDefault() {
        return plugin;
    }

    /**
     * {@inheritDoc}
     */
    public void earlyStartup() {
        // switch to the ui thread
        Display.getDefault().asyncExec(new Runnable() {

            public void run() {
                for (IWorkbenchWindow workbenchWindow : PlatformUI.getWorkbench()
                        .getWorkbenchWindows()) {
                    // hide the toolbar and the perspective area
                    WorkbenchWindow ww = (WorkbenchWindow) workbenchWindow;
                    ww.setCoolBarVisible(false);
                    ww.setPerspectiveBarVisible(false);
                    ww.setStatusLineVisible(false);
//                    ww.setFastViewBarVisible(false);

                    // find the composite that hosts the status line and dispose it
                    Shell shell = ww.getShell();
                    for (Control c : shell.getChildren()) {
                        if (c instanceof Composite) {
                            for (Control c2 : ((Composite) c).getChildren()) {
                                if (c2.getClass().getName().equals(STATUS_BAR_CLASS)) {
                                    c.setVisible(false);
                                    c.dispose();
                                }
                            }
                        }
                    }
                    shell.layout();

                    // hide ALL menus that we do not accept
                    // keep in mind, that the plugin.xml also hides elements!
                    MenuManager mm = ww.getMenuManager();
                    for (IContributionItem item : mm.getItems()) {
                        if (item instanceof MenuManager) {
                            boolean allInvisible = true;
                            for (IContributionItem innerItem : ((MenuManager) item).getItems()) {
                                if (acceptedMenuContribs.contains(innerItem.getId())) {
                                    allInvisible = false;
                                    specialTreatment(innerItem);
                                } else {
                                    innerItem.setVisible(false);
                                }
                                // System.out.println(innerItem.getId());
                            }
                            if (allInvisible) {
                                mm.remove(item);
                            }
                        }
                    }

                    // refresh the workbench
                    mm.update();
                    ww.updateActionBars();
                    ww.updateActionSets();
                }
            }
        });

        // check if no editor is opened, if it is the case, open a file dialog
        boolean openEditor = false;
        for (IWorkbenchWindow window : PlatformUI.getWorkbench().getWorkbenchWindows()) {
            for (IWorkbenchPage page : window.getPages()) {
                openEditor |= page.getEditorReferences().length != 0;
            }
        }

        if (!openEditor) {
            Display.getDefault().asyncExec(new Runnable() {

                public void run() {
                    try {
                        OpenLocalFileAction act = new OpenLocalFileAction();
                        IWorkbenchWindow activeWW =
                                PlatformUI.getWorkbench().getWorkbenchWindows()[0];
                        act.init(activeWW);
                        act.run();
                    } catch (Exception e) {
                        // silent fail ...
                    }
                }
            });
        }
    }

    private void specialTreatment(final IContributionItem item) {

        if (item.getId().equals(OPEN_FILE)) {
            // rename
            ActionSetContributionItem cItem = (ActionSetContributionItem) item;
            PluginActionContributionItem paItem =
                    (PluginActionContributionItem) cItem.getInnerItem();
            paItem.getAction().setText("Open...");
        } else if (item.getId().equals(ZOOM_TO_FIT)) {

            // the desired button state
            boolean zoomToFit = false;

            // check it according to KlighD's preference store
            String zoomString =
                    KlighdPlugin.getDefault().getPreferenceStore()
                            .getString(KlighdPreferences.ZOOM_STYLE);
            if (!Strings.isNullOrEmpty(zoomString)) {
                ZoomStyle zoomStyle = ZoomStyle.valueOf(zoomString);
                if (zoomStyle == ZoomStyle.ZOOM_TO_FIT) {
                    zoomToFit = true;
                }
            } else {
                // the default value is ZoomStyle.ZOOM_TO_FIT, thus we
                // activate the button if no value is stored in the preference store
                zoomToFit = true;
            }

            // FIXME hacky solution to set the button's toggle state
            try {
                Field f = item.getClass().getDeclaredField("toggleState");
                f.setAccessible(true);
                Object val = f.get(item);
                CommandStateProxy state = (CommandStateProxy) val;
                state.setValue(zoomToFit);
            } catch (Exception e) {
                StatusManager.getManager().handle(
                        new Status(IStatus.WARNING, PLUGIN_ID,
                                "Could not set the initial ZoomToFit state, "
                                        + "the button's state might be inconsistent."),
                        StatusManager.SHOW);
            }

        }
    }

}
