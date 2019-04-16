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

import java.awt.Image;
import java.awt.Toolkit;
import java.awt.image.BufferedImage;
import java.awt.image.DirectColorModel;
import java.awt.image.ImageObserver;
import java.awt.image.IndexColorModel;
import java.awt.image.WritableRaster;
import java.lang.reflect.Field;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;
import java.util.StringTokenizer;

import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.PaletteData;
import org.eclipse.swt.graphics.RGB;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import com.google.common.collect.Lists;

import de.cau.cs.kieler.klighd.krendering.KAreaPlacementData;
import de.cau.cs.kieler.klighd.krendering.KBackground;
import de.cau.cs.kieler.klighd.krendering.KColor;
import de.cau.cs.kieler.klighd.krendering.KContainerRendering;
import de.cau.cs.kieler.klighd.krendering.KEllipse;
import de.cau.cs.kieler.klighd.krendering.KFontSize;
import de.cau.cs.kieler.klighd.krendering.KForeground;
import de.cau.cs.kieler.klighd.krendering.KLineWidth;
import de.cau.cs.kieler.klighd.krendering.KPointPlacementData;
import de.cau.cs.kieler.klighd.krendering.KPolygon;
import de.cau.cs.kieler.klighd.krendering.KPolyline;
import de.cau.cs.kieler.klighd.krendering.KPosition;
import de.cau.cs.kieler.klighd.krendering.KRectangle;
import de.cau.cs.kieler.klighd.krendering.KRendering;
import de.cau.cs.kieler.klighd.krendering.KRenderingFactory;
import de.cau.cs.kieler.klighd.krendering.KText;
import de.cau.cs.kieler.klighd.krendering.KXPosition;
import de.cau.cs.kieler.klighd.krendering.KYPosition;
import ptolemy.data.expr.XMLParser;
import ptolemy.kernel.util.Attribute;
import ptolemy.vergil.icon.EditorIcon;
import ptolemy.vergil.icon.ImageIcon;

/**
 * Contains utility methods for handling SVG output from Ptolemy and graphics-related stuff.
 * 
 * <p>This class is not meant to be instantiated.</p>
 * 
 * @author ckru
 * @author cds
 * @kieler.rating proposed yellow cds 2015-02-23
 */
public final class GraphicsUtils {
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // SWT to SWT Graphics
    
    /**
     * Helper method for converting AWT images into SWT ones.
     * 
     * @param bufferedImage The {@link BufferedImage} resulting from the first step of conversion
     * @return The SWT {@link ImageData} for the given image
     */
    public static ImageData convertToSwt(final BufferedImage bufferedImage) {
        if (bufferedImage.getColorModel() instanceof DirectColorModel) {
            DirectColorModel colorModel = (DirectColorModel) bufferedImage.getColorModel();
            PaletteData palette = new PaletteData(colorModel.getRedMask(),
                    colorModel.getGreenMask(), colorModel.getBlueMask());
            ImageData data = new ImageData(bufferedImage.getWidth(), bufferedImage.getHeight(),
                    colorModel.getPixelSize(), palette);
            WritableRaster raster = bufferedImage.getRaster();
            final int rasterSize = 3;
            int[] pixelArray = new int[rasterSize];
            for (int y = 0; y < data.height; y++) {
                for (int x = 0; x < data.width; x++) {
                    raster.getPixel(x, y, pixelArray);
                    int pixel = palette.getPixel(new RGB(pixelArray[0], pixelArray[1],
                            pixelArray[2]));
                    data.setPixel(x, y, pixel);
                }
            }
            return data;
        } else if (bufferedImage.getColorModel() instanceof IndexColorModel) {
            IndexColorModel colorModel = (IndexColorModel) bufferedImage.getColorModel();
            int size = colorModel.getMapSize();
            byte[] reds = new byte[size];
            byte[] greens = new byte[size];
            byte[] blues = new byte[size];
            colorModel.getReds(reds);
            colorModel.getGreens(greens);
            colorModel.getBlues(blues);
            RGB[] rgbs = new RGB[size];
            final int mask = 0xFF;
            for (int i = 0; i < rgbs.length; i++) {
                rgbs[i] = new RGB(reds[i] & mask, greens[i] & mask, blues[i] & mask);
            }
            PaletteData palette = new PaletteData(rgbs);
            ImageData data = new ImageData(bufferedImage.getWidth(), bufferedImage.getHeight(),
                    colorModel.getPixelSize(), palette);
            data.transparentPixel = colorModel.getTransparentPixel();
            WritableRaster raster = bufferedImage.getRaster();
            int[] pixelArray = new int[1];
            for (int y = 0; y < data.height; y++) {
                for (int x = 0; x < data.width; x++) {
                    raster.getPixel(x, y, pixelArray);
                    data.setPixel(x, y, pixelArray[0]);
                }
            }
            return data;
        }
        return null;
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // EditorIcon Loading
    
    
    /**
     * Try to wait for the images or for the scaled images contained in the icon hierarchy rooted at the
     * given {@code EditorIcon} to finish loading. This method has to be called from the AWT event queue.
     * Also, it has to be called twice from separate {@link Runnable}s, once with {@code firstCall} set
     * to {@code true}, once with it set to {@code false}.
     * 
     * @param editorIcon the editor icon to load.
     * @param firstCall whether this is the first call to this method or the second.
     */
    public static void waitForImages(final EditorIcon editorIcon, final boolean firstCall) {
        ImageReadynessNotifier notifier = new ImageReadynessNotifier();
        
        // Iterate over the complete hierarchy of the editor icon
        Queue<EditorIcon> icons = Lists.newLinkedList();
        icons.add(editorIcon);
        
        while (!icons.isEmpty()) {
            EditorIcon currentIcon = icons.poll();
            
            // If we have an ImageIcon, we need to wait for its images to load
            if (currentIcon instanceof ImageIcon) {
                notifier.addImageIcon((ImageIcon) currentIcon, !firstCall);
            }
            
            // Check for sub-icons that are drawn; these need to be traversed as well
            for (Object attributeObject : currentIcon.attributeList()) {
                Attribute attribute = (Attribute) attributeObject;
                
                for (Object subIconObject : attribute.attributeList(EditorIcon.class)) {
                    icons.add((EditorIcon) subIconObject);
                }
            }
        }
        
        // Wait for the images to finish loading
        notifier.waitForAllImages();
    }
    
    /**
     * Helper class that provides the means to wait for a number of {@code ImageIcon} instances to
     * finish loading their images or scaled images.
     * 
     * @author cds
     */
    private static class ImageReadynessNotifier implements ImageObserver {
        /** The monitor used for synchronization. */
        private Object monitor = new Object();
        /** List of images we're waiting for. */
        private List<Image> images = Lists.newLinkedList();
        
        
        /**
         * Add the given ImageIcon to the list of ImageIcon we're waiting for to finish loading theirs
         * images.
         * 
         * @param imageIcon the new ImageIcon to wait for.
         */
        public void addImageIcon(final ImageIcon imageIcon, final boolean scaled) {
            synchronized (monitor) {
                // We need to find the imageIcon's private _scaledImage
                Image scaledImage = retrieveImage(imageIcon, scaled);
                if (scaledImage != null) {
                    // Wait for it to be fully prepared
                    Toolkit tk = Toolkit.getDefaultToolkit();
                    if ((tk.checkImage(scaledImage, -1, -1, this) & ImageObserver.ALLBITS) == 0) {
                        // The image is not ready yet, wait for it
                        images.add(scaledImage);
                    }
                }
            }
        }
        
        /**
         * Waits until all registered image icons have finished loading their scaled images.
         */
        public void waitForAllImages() {
            synchronized (monitor) {
                while (!images.isEmpty()) {
                    try {
                        monitor.wait();
                    } catch (InterruptedException e) {
                        // No need to do anything
                    }
                }
            }
        }        
        
        /**
         * Tries to retrieve the value of the private {@code _image} or {@code _scaledImage} fields
         * of the given image icon.
         * 
         * @param imageIcon the image icon whose private images to return.
         * @param scaled if {@code true}, the {@code _scaledImage} is returned; otherwise, the
         *               {@code _image} is returned.
         * @return the image or {@code null} if we were unable to retrieve one.
         */
        private Image retrieveImage(final ImageIcon imageIcon, final boolean scaled) {
            String fieldName = scaled ? "_scaledImage" : "_image";
            
            try {
                Field imageField = ImageIcon.class.getDeclaredField(fieldName);
                imageField.setAccessible(true);
                return (Image) imageField.get(imageIcon);
            } catch (Exception e) {
                // We can't get at the image
                System.out.println(e);
                return null;
            }
        }

        
        public boolean imageUpdate(Image img, int infoflags, int x, int y, int width, int height) {
            synchronized (monitor) {
                // Check if it has finished loading
                if ((infoflags & ImageObserver.ALLBITS) != 0) {
                    // Remove it from the list; if the list is now empty, notify observers
                    images.remove(img);
                    if (images.isEmpty()) {
                        monitor.notify();
                    }
                    return false;
                } else {
                    return true;
                }
            }
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // SVG Repair

    /**
     * Converts an SVG description from Ptolemy into an SVG description that is compatible to the
     * SVG standard.
     * 
     * @param svg
     *            the string describing an svg in xml
     * @return an svg description compatible with the svg standard or {@code null} if something went
     *         wrong.
     */
    public static Document repairSvg(final Document doc) {
        try {
            Element svgElement = (Element) doc.getElementsByTagName("svg").item(0);
            NodeList nodeList = doc.getElementsByTagName("rect");
            int xoffset = 0;
            int yoffset = 0;
            
            // We have to set the size of the whole thing in the <svg> tag (thats missing in ptolemy)
            // That is easy if the top element is a rectangle.
            // Also we have to calculate an offset by which to shift each element
            // (in Ptolemy, (0,0) is the center point, while in our world, it is the top left corner).
            if (nodeList.getLength() != 0) {
                Element rectElement = (Element) doc.getElementsByTagName("rect").item(0);
                svgElement.setAttribute("height",
                        String.valueOf(Integer.parseInt(rectElement.getAttribute("height")) + 1));
                svgElement.setAttribute("width",
                        String.valueOf(Integer.parseInt(rectElement.getAttribute("width")) + 1));
                xoffset = (int) Math.abs(Float.parseFloat(rectElement.getAttribute("x")));
                yoffset = (int) Math.abs(Float.parseFloat(rectElement.getAttribute("y")));
                
                // The topmost element is not a rectangle. Try to find the topmost svg element.
                // If it has points (its a polygon or something) use those
                // to calculate the needed size and offset.
            } else {
                // TODO hacked else case, think of something better
                int childPointer = 0;
                Object object = svgElement.getChildNodes().item(childPointer);
                while (!(object instanceof Element) && (object != svgElement)) {
                    object = svgElement.getElementsByTagName("*").item(childPointer);
                }
                Element firstElement = (Element) object;
                if (firstElement.hasAttribute("points")) {
                    String points = firstElement.getAttribute("points");
                    String[] splittedPoints = points.split(" +");
                    // String firstPoint = splittedPoints[0];
                    // String[] firstPointCoords = firstPoint.split(",");
                    List<Float> pointsX = new LinkedList<Float>();
                    List<Float> pointsY = new LinkedList<Float>();
                    for (String singlePoint : splittedPoints) {
                        String[] pointCoord = singlePoint.split(",");
                        pointsX.add(Float.parseFloat(pointCoord[0]));
                        pointsY.add(Float.parseFloat(pointCoord[1]));
                    }
                    float minX = Collections.min(pointsX);
                    float minY = Collections.min(pointsY);
                    xoffset = (int) Math.abs(minX);
                    yoffset = (int) Math.abs(minY);
                    float maxX = Collections.max(pointsX);
                    float maxY = Collections.max(pointsY);
                    svgElement.setAttribute("width", String.valueOf(maxX + xoffset + 1));
                    svgElement.setAttribute("height", String.valueOf(maxY + yoffset + 1));
                } else if (firstElement.hasAttribute("r")) {
                    int r = (int) Math.abs(Float.parseFloat(firstElement.getAttribute("r")));
                    xoffset = r;
                    yoffset = r;
                    svgElement.setAttribute("height", String.valueOf(r * 2));
                    svgElement.setAttribute("width", String.valueOf(r * 2));
                }
            }
            
            // shift all rectangles by the offset calculated beforehand
            for (int i = 0; i < doc.getElementsByTagName("rect").getLength(); i++) {
                Element e = (Element) doc.getElementsByTagName("rect").item(i);
                if (e.hasAttribute("x") && e.hasAttribute("y") && e.hasAttribute("style")) {
                    Double x = Double.parseDouble(e.getAttribute("x"));
                    Double y = Double.parseDouble(e.getAttribute("y"));
                    x += xoffset;
                    y += yoffset;
                    e.setAttribute("x", String.valueOf(x));
                    e.setAttribute("y", String.valueOf(y));
                    e.setAttribute("style",
                            e.getAttribute("style").concat(";stroke:black;stroke-width:1"));
                }
            }
            
            // shift all circles by the offset calculated beforehand
            for (int i = 0; i < doc.getElementsByTagName("circle").getLength(); i++) {
                Element e = (Element) doc.getElementsByTagName("circle").item(i);
                if (e.hasAttribute("cx") && e.hasAttribute("cy")) {
                    float x = Float.parseFloat(e.getAttribute("cx"));
                    float y = Float.parseFloat(e.getAttribute("cy"));
                    x += xoffset;
                    y += yoffset;
                    e.setAttribute("cx", String.valueOf(x));
                    e.setAttribute("cy", String.valueOf(y));
                }
                e.setAttribute("style",
                        e.getAttribute("style").concat(";stroke:black;stroke-width:1"));
            }
            
            // shift all polygons by the offset calculated beforehand
            for (int i = 0; i < doc.getElementsByTagName("polygon").getLength(); i++) {
                Element e = (Element) doc.getElementsByTagName("polygon").item(i);
                if (e.hasAttribute("points")) {
                    StringBuffer newpoints = new StringBuffer();
                    String allpoints = e.getAttribute("points");
                    String[] pointsarray = allpoints.split(" +");
                    for (String coords : pointsarray) {
                        String[] coordsarray = coords.split(",");
                        float x = Float.parseFloat(coordsarray[0]);
                        float y = Float.parseFloat(coordsarray[1]);
                        x += xoffset;
                        y += yoffset;
                        newpoints.append(String.valueOf(x) + "," + String.valueOf(y) + " ");

                    }
                    e.setAttribute("points", newpoints.toString());
                    e.setAttribute("style",
                            e.getAttribute("style").concat(";stroke:black;stroke-width:1"));
                }
            }
            
            // shift all polylines by the offset calculated beforehand
            for (int i = 0; i < doc.getElementsByTagName("polyline").getLength(); i++) {
                Element e = (Element) doc.getElementsByTagName("polyline").item(i);
                if (e.hasAttribute("points")) {
                    StringBuffer newpoints = new StringBuffer();
                    String allpoints = e.getAttribute("points");
                    String[] pointsarray = allpoints.split(" +");
                    for (String coords : pointsarray) {
                        String[] coordsarray = coords.split(",");
                        float x = Float.parseFloat(coordsarray[0]);
                        float y = Float.parseFloat(coordsarray[1]);
                        x += xoffset;
                        y += yoffset;
                        newpoints.append(String.valueOf(x) + "," + String.valueOf(y) + " ");

                    }
                    e.setAttribute("points", newpoints.toString());
                }
            }
            
            // shift all lines by the offset calculated beforehand
            for (int i = 0; i < doc.getElementsByTagName("line").getLength(); i++) {
                Element e = (Element) doc.getElementsByTagName("line").item(i);
                if (e.hasAttribute("x1") && e.hasAttribute("y1") && e.hasAttribute("x2")
                        && e.hasAttribute("y2")) {
                    float x1 = Float.parseFloat(e.getAttribute("x1"));
                    float y1 = Float.parseFloat(e.getAttribute("y1"));
                    float x2 = Float.parseFloat(e.getAttribute("x2"));
                    float y2 = Float.parseFloat(e.getAttribute("y2"));
                    x1 += xoffset;
                    y1 += yoffset;
                    x2 += xoffset;
                    y2 += yoffset;
                    e.setAttribute("x1", String.valueOf(x1));
                    e.setAttribute("y1", String.valueOf(y1));
                    e.setAttribute("x2", String.valueOf(x2));
                    e.setAttribute("y2", String.valueOf(y2));
                }
                e.setAttribute("style",
                        e.getAttribute("style").concat(";stroke:black;stroke-width:1"));
            }
            
            // shift all images by the offset calculated beforehand
            for (int i = 0; i < doc.getElementsByTagName("image").getLength(); i++) {
                Element e = (Element) doc.getElementsByTagName("image").item(i);
                if (e.hasAttribute("x") && e.hasAttribute("y")) {
                    float x = Float.parseFloat(e.getAttribute("x"));
                    float y = Float.parseFloat(e.getAttribute("y"));
                    x += xoffset;
                    y += yoffset;
                    e.setAttribute("x", String.valueOf(x));
                    e.setAttribute("y", String.valueOf(y));
                }
            }
            
            // shift all ellipses by the offset calculated beforehand
            for (int i = 0; i < doc.getElementsByTagName("ellipse").getLength(); i++) {
                Element e = (Element) doc.getElementsByTagName("ellipse").item(i);
                if (e.hasAttribute("cx") && e.hasAttribute("cy")) {
                    float x = Float.parseFloat(e.getAttribute("cx"));
                    float y = Float.parseFloat(e.getAttribute("cy"));
                    x += xoffset;
                    y += yoffset;
                    e.setAttribute("cx", String.valueOf(x));
                    e.setAttribute("cy", String.valueOf(y));
                }
            }
            
            // shift all text elements by the offset calculated beforehand
            for (int i = 0; i < doc.getElementsByTagName("text").getLength(); i++) {
                Element e = (Element) doc.getElementsByTagName("text").item(i);
                if (e.hasAttribute("x") && e.hasAttribute("y")) {
                    float x = Float.parseFloat(e.getAttribute("x"));
                    float y = Float.parseFloat(e.getAttribute("y"));
                    x += xoffset;
                    y += yoffset;
                    e.setAttribute("x", String.valueOf(x));
                    e.setAttribute("y", String.valueOf(y));
                }
            }
            
            return doc;
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        // Something went wrong
        return null;
    }

    /**
     * Adds necessary blanks to an SVG description because Ptolemy is bugged.
     * 
     * @param input
     *            the broken svg description
     * @return a repaired version of the input that an xml parser can understand.
     */
    public static String repairString(final String input) {
        String[] parts = input.split("\"");
        StringBuffer output = new StringBuffer();
        for (int i = 0; i < parts.length; i += 2) {
            if (i < parts.length - 1) {
                output.append(parts[i] + "\"" + parts[i + 1] + "\" ");
            } else {
                output.append(parts[i]);
            }
        }
        return output.toString();
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // SVG to KRendering
    
    /**
     * Create a krendering figure out of an svg document.
     * 
     * @param doc
     *            the svg document as string
     * @return the krendering equivalent to the svg or {@code null} if the String couldn't be parsed.
     */
    public static KRendering createFigureFromSvg(final String svgString) {
        try {
            XMLParser parser = new XMLParser();
            Document doc = parser.parser(svgString);
            return createFigureFromSvg(doc);
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * Create a krendering figure out of an svg document.
     * 
     * @param doc
     *            the svg document
     * @return the krendering equivalent to the svg
     */
    public static KRendering createFigureFromSvg(final Document doc) {
        Element svgElement = (Element) doc.getElementsByTagName("svg").item(0);
        KRenderingFactory factory = KRenderingFactory.eINSTANCE;
        
        // Make an invisible container to hold the visible figures because we don't know the
        // structure of the svg.
        KContainerRendering rootFigure = factory.createKRectangle();

//        KInvisibility invisibility = factory.createKInvisibility();//.createKBackgroundVisibility();
//        invisibility.setInvisible(true);//.setVisible(false);
//        KInvisibility foregroundInvisibility = factory.createKInvisibility();
//        foregroundInvisibility.setInvisible(false);
//        
//        rootFigure.getStyles().add(invisibility);
//        
//        rootFigure.getStyles().add(foregroundInvisibility);
        
        // IFigure rootFigure = new Panel();
        KAreaPlacementData placement = factory.createKAreaPlacementData();
        KPosition topleft = factory.createKPosition();
        KXPosition<?> left = factory.createKLeftPosition();
        left.setAbsolute(0);
        topleft.setX(left);
        KYPosition<?> top = factory.createKTopPosition();
        top.setAbsolute(0);
        topleft.setY(top);
        KPosition bottomright = factory.createKPosition();
        KXPosition<?> right = factory.createKLeftPosition();
        right.setAbsolute(Float.parseFloat(svgElement.getAttribute("width")));
        bottomright.setX(right);
        KYPosition<?> bottom = factory.createKTopPosition();
        bottom.setAbsolute(Float.parseFloat(svgElement.getAttribute("height")));
        bottomright.setY(bottom);
        placement.setTopLeft(topleft);
        placement.setBottomRight(bottomright);
        //placement.setHeightHint(Float.parseFloat(svgElement.getAttribute("height")));
        //placement.setWidthHint(Float.parseFloat(svgElement.getAttribute("width")));
        rootFigure.setPlacementData(placement);
        //rootFigure.setChildPlacement(factory.createKStackPlacement());
        
        // suppress the visibility of the root rectangle
        //  the 'invisible' flag of the KInvisibility is initially 'true'
        rootFigure.getStyles().add(factory.createKInvisibility());
        rootFigure = buildFigure(svgElement, rootFigure);
        return rootFigure;
    }

    /**
     * Parsing the svg and creating krenderings accordingly. Builds a hirachical structure.
     * 
     * @param root
     *            the top level svg element.
     * @param parentFigure
     *            an invisible krendering as container for the actual figures
     * @return a hirachical krendering representing the svg
     */
    private static KContainerRendering buildFigure(final Element root,
            final KContainerRendering parentFigure) {
        
        NodeList childList = root.getChildNodes();
        KRenderingFactory factory = KRenderingFactory.eINSTANCE;
        for (int i = 0; i < childList.getLength(); i++) {
            Node child = childList.item(i);
            if (child instanceof Element) {
                Element childElement = (Element) child;
                String tag = childElement.getTagName();
                // make a RectangleFigure from a rectangle element
                if (tag.equals("rect")) {
                    KRectangle figure = factory.createKRectangle();
                    KXPosition<?> left = factory.createKLeftPosition();
                    left.setAbsolute(Float.parseFloat(childElement.getAttribute("x")));

                    KYPosition<?> top = factory.createKTopPosition();
                    top.setAbsolute(Float.parseFloat(childElement.getAttribute("y")));

                    KXPosition<?> right = factory.createKLeftPosition();
                    right.setAbsolute(left.getAbsolute()
                            + Float.parseFloat(childElement.getAttribute("width")));

                    KYPosition<?> bottom = factory.createKTopPosition();
                    bottom.setAbsolute(top.getAbsolute()
                            + Float.parseFloat(childElement.getAttribute("height")));

                    String style = (String) childElement.getAttribute("style");

                    KAreaPlacementData placement = factory.createKAreaPlacementData();

                    KPosition topleft = factory.createKPosition();
                    topleft.setX(left);
                    topleft.setY(top);

                    KPosition bottomright = factory.createKPosition();
                    bottomright.setX(right);
                    bottomright.setY(bottom);

                    placement.setTopLeft(topleft);
                    placement.setBottomRight(bottomright);

                    figure.setPlacementData(placement);
                    applyStyle(figure, style);
                    parentFigure.getChildren().add(buildFigure(childElement, figure));
                    // make a CircleFigure from a circle element.
                    // structure is different between draw2d and svg so positions are a bit hacked
                } else if (tag.equals("circle")) {

                    KEllipse figure = factory.createKEllipse();

                    float radius = Float.parseFloat(childElement.getAttribute("r"));
                    
                    KXPosition<?> left = factory.createKLeftPosition();
                    left.setAbsolute((Float.parseFloat(childElement.getAttribute("cx")) - radius));

                    KYPosition<?> top = factory.createKTopPosition();
                    top.setAbsolute((Float.parseFloat(childElement.getAttribute("cy")) - radius));

                    KXPosition<?> right = factory.createKLeftPosition();
                    right.setAbsolute(left.getAbsolute()
                            + (radius * 2));

                    KYPosition<?> bottom = factory.createKTopPosition();
                    bottom.setAbsolute(top.getAbsolute()
                            + (radius * 2));

                    
                    String style = (String) childElement.getAttribute("style");

                    KAreaPlacementData placement = factory.createKAreaPlacementData();

                    KPosition topleft = factory.createKPosition();
                    topleft.setX(left);
                    topleft.setY(top);

                    KPosition bottomright = factory.createKPosition();
                    bottomright.setX(right);
                    bottomright.setY(bottom);

                    placement.setTopLeft(topleft);
                    placement.setBottomRight(bottomright);

                    figure.setPlacementData(placement);
                    applyStyle(figure, style);
                    parentFigure.getChildren().add(buildFigure(childElement, figure));
                    // make a CircleFigure from a ellipse element.
                    // structure is different between draw2d and svg so positions are a bit hacked
                } else if (tag.equals("ellipse")) {
                    KEllipse figure = factory.createKEllipse();

                    float xradius = Float.parseFloat(childElement.getAttribute("rx"));
                    float yradius = Float.parseFloat(childElement.getAttribute("ry"));
                    
                    KXPosition<?> left = factory.createKLeftPosition();
                    left.setAbsolute(Float.parseFloat(childElement.getAttribute("cx")) - xradius);

                    KYPosition<?> top = factory.createKTopPosition();
                    top.setAbsolute(Float.parseFloat(childElement.getAttribute("cy")) - yradius);

                    KXPosition<?> right = factory.createKLeftPosition();
                    right.setAbsolute(left.getAbsolute()
                            + (xradius * 2));

                    KYPosition<?> bottom = factory.createKTopPosition();
                    bottom.setAbsolute(top.getAbsolute()
                            + (yradius * 2));

                    String style = (String) childElement.getAttribute("style");

                    KAreaPlacementData placement = factory.createKAreaPlacementData();

                    KPosition topleft = factory.createKPosition();
                    topleft.setX(left);
                    topleft.setY(top);

                    KPosition bottomright = factory.createKPosition();
                    bottomright.setX(right);
                    bottomright.setY(bottom);

                    placement.setTopLeft(topleft);
                    placement.setBottomRight(bottomright);
                    figure.setPlacementData(placement);
                    applyStyle(figure, style);
                    parentFigure.getChildren().add(buildFigure(childElement, figure));
                    // make a PolyLineShape from a line element
                } else if (tag.equals("line")) {

                    KPolyline figure = factory.createKPolyline();

                    KXPosition<?> x1 = factory.createKLeftPosition();
                    x1.setAbsolute(Float.parseFloat(childElement.getAttribute("x1")));

                    KYPosition<?> y1 = factory.createKTopPosition();
                    y1.setAbsolute(Float.parseFloat(childElement.getAttribute("y1")));

                    KXPosition<?> x2 = factory.createKLeftPosition();
                    x2.setAbsolute(Float.parseFloat(childElement.getAttribute("x2")));

                    KYPosition<?> y2 = factory.createKTopPosition();
                    y2.setAbsolute(Float.parseFloat(childElement.getAttribute("y2")));

                    String style = (String) childElement.getAttribute("style");

                    
                    //KPointPlacementData placement = factory.createKPointPlacementData();//createKPolylinePlacementData();

                    KPosition p1 = factory.createKPosition();
                    p1.setX(x1);
                    p1.setY(y1);

                    KPosition p2 = factory.createKPosition();
                    p2.setX(x2);
                    p2.setY(y2);
                    
                    //placement.getPoints().add(p1);
                    //placement.getPoints().add(p2);
                    figure.getPoints().add(p1);
                    figure.getPoints().add(p2);
                    //figure.setPlacementData(placement);
                    applyStyle(figure, style);
                    
                    
                    parentFigure.getChildren().add(buildFigure(childElement, figure));
                    // make a PolylineShape from a polyline element.
                } else if (tag.equals("polyline")) {
                    String allpoints = childElement.getAttribute("points");
                    String style = (String) childElement.getAttribute("style");
                    String[] pointsarray = allpoints.split(" +");
                    //KPolylinePlacementData placement = factory.createKPolylinePlacementData();
                    KPolyline figure = factory.createKPolyline();
                    for (String coords : pointsarray) {
                        String[] coordsarray = coords.split(",");

                        KXPosition<?> x = factory.createKLeftPosition();
                        x.setAbsolute(Float.parseFloat(coordsarray[0]));

                        KYPosition<?> y = factory.createKTopPosition();
                        y.setAbsolute(Float.parseFloat(coordsarray[1]));

                        KPosition p = factory.createKPosition();
                        p.setX(x);
                        p.setY(y);

                        figure.getPoints().add(p);
                        //placement.getPoints().add(p);
                    }
                    
                    //figure.setPlacementData(placement);
                    applyStyle(figure, style);
                    parentFigure.getChildren().add(buildFigure(childElement, figure));

                    // make a PolygonShape from a polygon element
                } else if (tag.equals("polygon")) {
                    String allpoints = childElement.getAttribute("points");
                    String style = (String) childElement.getAttribute("style");
                    String[] pointsarray = allpoints.split(" +");
                    //KPolylinePlacementData placement = factory.createKPolylinePlacementData();

                    KPolygon figure = factory.createKPolygon();
                    
                    for (String coords : pointsarray) {
                        String[] coordsarray = coords.split(",");

                        KXPosition<?> x = factory.createKLeftPosition();
                        x.setAbsolute(Float.parseFloat(coordsarray[0]));

                        KYPosition<?> y = factory.createKTopPosition();
                        y.setAbsolute(Float.parseFloat(coordsarray[1]));

                        KPosition p = factory.createKPosition();
                        p.setX(x);
                        p.setY(y);

                        figure.getPoints().add(p);
                        //placement.getPoints().add(p);
                    }
                    

                    //figure.setPlacementData(placement);
                    applyStyle(figure, style);
                    parentFigure.getChildren().add(buildFigure(childElement, figure));

                    // make a Label from a text element
                    // TODO weird behavior of y value
                } else if (tag.equals("text")) {
                    KXPosition<?> x = factory.createKLeftPosition();
                    x.setAbsolute(Float.parseFloat(childElement.getAttribute("x")));

                    KYPosition<?> y = factory.createKTopPosition();
                    y.setAbsolute(Float.parseFloat(childElement.getAttribute("y")));

                    String style = (String) childElement.getAttribute("style");
                    String text = childElement.getTextContent();
                    text = text.replaceAll("\n", "");
                    text = text.trim();

                    KText figure = factory.createKText();
                    figure.setText(text);
                    
                    KPointPlacementData placement = factory.createKPointPlacementData();

                    KPosition topleft = factory.createKPosition();
                    topleft.setX(x);
                    topleft.setY(y);
                    //System.out.println("???????????" + text);
                    placement.setReferencePoint(topleft);

                    
                    applyTextStyle(figure, style, placement);

                                        // KPosition bottomright = factory.createKPosition();
                    // bottomright.setX(right);
                    // bottomright.setY(bottom);
                    figure.setPlacementData(placement);
                    /*
                     * figure.getBounds() .setLocation( new PrecisionPoint(x, y -
                     * (figure.getTextBounds().getSize().height - 2)));
                     * figure.getBounds().setSize(figure.getTextBounds().getSize());
                     */
                    // figure.setLayoutManager(new BorderLayout());
                    parentFigure.getChildren().add(figure);
                    // make an ImageFigureEx out of an image element
                } else if (tag.equals("image")) {
                    KXPosition<?> left = factory.createKLeftPosition();
                    left.setAbsolute(Float.parseFloat(childElement.getAttribute("x")));

                    KYPosition<?> top = factory.createKTopPosition();
                    top.setAbsolute(Float.parseFloat(childElement.getAttribute("y")));

                    KXPosition<?> right = factory.createKLeftPosition();
                    right.setAbsolute(left.getAbsolute()
                            + Float.parseFloat(childElement.getAttribute("width")));

                    KYPosition<?> bottom = factory.createKTopPosition();
                    bottom.setAbsolute(top.getAbsolute()
                            + Float.parseFloat(childElement.getAttribute("height")));

                    String link = (String) childElement.getAttribute("xlink:href");
                    //String style = (String) childElement.getAttribute("style");
                    URL url = ClassLoader.getSystemResource(link);
                    if (url == null) {
                        try {
                            url = new URL(link);
                        } catch (MalformedURLException e) {
                            e.printStackTrace();
                        }
                    }
                    // Image img = null;
                    KRectangle figure = null;
                    // try {
                    // img = new Image(null, url.openStream());
                    figure = factory.createKRectangle();//factory.createKImage();
                    //figure.setImagePath(url.getPath());
                    // } catch (IOException e) {
                    
                    // e.printStackTrace();
                    // }

                    KAreaPlacementData placement = factory.createKAreaPlacementData();

                    KPosition topleft = factory.createKPosition();
                    topleft.setX(left);
                    topleft.setY(top);

                    KPosition bottomright = factory.createKPosition();
                    bottomright.setX(right);
                    bottomright.setY(bottom);
                    
                    figure.setPlacementData(placement);
                    
                    /*
                    applyStyle(figure, style);
                    */
                    parentFigure.getChildren().add(buildFigure(childElement, figure));

                }

            }
        }
        return parentFigure;
    }

    /**
     * Applys the style attribute of the svg element to the krendering.
     * 
     * @param figure
     *            the krendering whose style to set
     * @param style
     *            the style as a string
     */
    private static KContainerRendering applyStyle(final KContainerRendering figure,
            final String style) {
        
        KRenderingFactory factory = KRenderingFactory.eINSTANCE;
        if (style != null) {
            StringTokenizer t = new StringTokenizer(style, ";");

            while (t.hasMoreTokens()) {
                String string = t.nextToken().trim();
                int index = string.indexOf(":");
                String name = string.substring(0, index);
                String value = string.substring(index + 1);
                // fill might be background, stroke foreground. Works fine so far.
                if (name.equals("fill")) {
                    KBackground fill = factory.createKBackground();
                    KColor color = lookupColor(value);
                    fill.setColor(color);
                    figure.getStyles().add(fill);
                } else if (name.equals("stroke")) {
                    KForeground stroke = factory.createKForeground();
                    KColor color = lookupColor(value);
                    stroke.setColor(color);
                    figure.getStyles().add(stroke);
                } else if (name.equals("stroke-width")) {
                    Float width = Float.parseFloat(value);
                    KLineWidth strokeWidth = factory.createKLineWidth();
                    strokeWidth.setLineWidth(width.intValue());
                    figure.getStyles().add(strokeWidth);
                }
            }
        }
        return figure;
    }

    /**
     * Applys the style attribute of the svg element to the krendering.
     * 
     * @param figure
     *            the krendering whoose style to set
     * @param style
     *            the style as a string
     */
    private static KContainerRendering applyTextStyle(final KText figure, final String style, KPointPlacementData placement) {
        KRenderingFactory factory = KRenderingFactory.eINSTANCE;
        if (style != null) {
            StringTokenizer t = new StringTokenizer(style, ";");

            while (t.hasMoreTokens()) {
                String string = t.nextToken().trim();
                int index = string.indexOf(":");
                String name = string.substring(0, index);
                String value = string.substring(index + 1);
                // foreground color determines the text color
                if (name.equals("fill")) {
                   // KForegroundColor fill = factory.createKForegroundColor();
                    //figure.getStyles().add(lookupColor(value, fill));
                    // some hacked size stuff without having a fitting font.
                } else if (name.equals("font-size")) {
                    
                    int size = Integer.parseInt(value);
                    KFontSize fontSize = factory.createKFontSize();
                    fontSize.setSize(size);
                    figure.getStyles().add(fontSize);
                    
                    KPosition position = placement.getReferencePoint();
                    position.getY().setAbsolute(position.getY().getAbsolute() - size);
                    
                    /*
                     * if (figure instanceof Label) { FontData[] fonts =
                     * PlatformUI.getWorkbench().getDisplay() .getFontList("arial", true); FontData
                     * fd = fonts[0]; fd.setHeight(size - 2); Font font = new
                     * Font(PlatformUI.getWorkbench().getDisplay(), fd); ((Label)
                     * figure).setFont(font); }
                     */
                }
                // TODO set a font.Problem: Svg has an attribute that loosely describes the font
                // family.
                // This has to be mapped to existing fonts on a specific system.
            }
        }
        return null;//figure;
    }

    /**
     * Make a KRendering KColor object out of a color name.
     * 
     * @param color
     *            string representation of a color
     * @return the color described by the string. black if not found.
     */
    public static KColor lookupColor(final String color) {
        KColor kcolor = KRenderingFactory.eINSTANCE.createKColor();
        
        String s = color.toLowerCase();
        if (s.equals("black")) {
            kcolor.setRed(0);
            kcolor.setGreen(0);
            kcolor.setBlue(0);
        } else if (s.equals("blue")) {
            kcolor.setRed(0);
            kcolor.setGreen(0);
            kcolor.setBlue(255);
        } else if (s.equals("cyan")) {
            kcolor.setRed(0);
            kcolor.setGreen(255);
            kcolor.setBlue(255);
        } else if (s.equals("darkgray") || s.equals("darkgrey")) {
            kcolor.setRed(64);
            kcolor.setGreen(64);
            kcolor.setBlue(64);
        } else if (s.equals("lightgray") || s.equals("lightgrey")) {
            kcolor.setRed(192);
            kcolor.setGreen(192);
            kcolor.setBlue(192);
        } else if (s.equals("gray") || s.equals("grey")) {
            kcolor.setRed(128);
            kcolor.setGreen(128);
            kcolor.setBlue(128);
        } else if (s.equals("green")) {
            kcolor.setRed(0);
            kcolor.setGreen(255);
            kcolor.setBlue(0);
        } else if (s.equals("orange")) {
            kcolor.setRed(255);
            kcolor.setGreen(196);
            kcolor.setBlue(0);
        } else if (s.equals("red")) {
            kcolor.setRed(255);
            kcolor.setGreen(0);
            kcolor.setBlue(0);
        } else if (s.equals("white")) {
            kcolor.setRed(255);
            kcolor.setGreen(255);
            kcolor.setBlue(255);
        } else if (s.equals("yellow")) {
            kcolor.setRed(255);
            kcolor.setGreen(255);
            kcolor.setBlue(0);
        } else {
            kcolor.setRed(0);
            kcolor.setGreen(0);
            kcolor.setBlue(0);
        }

        return kcolor;
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    
    /**
     * This class is not meant to be instantiated.
     */
    private GraphicsUtils() {
        
    }
}
