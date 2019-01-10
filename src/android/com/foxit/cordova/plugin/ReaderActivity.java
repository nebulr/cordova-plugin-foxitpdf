package com.foxit.cordova.plugin;

import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Color;
import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Menu;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;
import com.foxit.sdk.PDFViewCtrl;
import com.foxit.sdk.PDFViewCtrl.IDocEventListener;
import com.foxit.sdk.pdf.PDFDoc;
import com.foxit.sdk.pdf.fdf.FDFDoc;
import com.foxit.uiextensions.UIExtensionsManager;
import com.foxit.uiextensions.UIExtensionsManager.Config;
import com.foxit.uiextensions.home.IHomeModule;
import com.foxit.uiextensions.pdfreader.impl.PDFReader;
import com.foxit.uiextensions.pdfreader.impl.PDFReader.OnFinishListener;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileReader;
import java.nio.charset.Charset;
import org.apache.cordova.LOG;
import org.json.JSONObject;

public class ReaderActivity extends FragmentActivity {
    public PDFReader mPDFReader;
    private FDFDoc annotations;
    private File file;
    public PDFViewCtrl pdfViewCtrl;

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        RelativeLayout relativeLayout = new RelativeLayout(this);
        LayoutParams params = new LayoutParams(-1, -1);
        this.pdfViewCtrl = new PDFViewCtrl(this);
        relativeLayout.addView(this.pdfViewCtrl, params);
        relativeLayout.setWillNotDraw(false);
        relativeLayout.setBackgroundColor(Color.argb(255, 225, 225, 225));
        relativeLayout.setDrawingCacheEnabled(true);
        setContentView(relativeLayout);
        UIExtensionsManager uiextensionsManager = new UIExtensionsManager(this, relativeLayout, this.pdfViewCtrl, new Config(new ByteArrayInputStream("{\n    \"defaultReader\": true,\n    \"modules\": {\n        \"readingbookmark\": true,\n        \"outline\": true,\n        \"annotations\": true,\n        \"thumbnail\" : true,\n        \"attachment\": true,\n        \"signature\": true,\n        \"search\": true,\n        \"pageNavigation\": true,\n        \"form\": true,\n        \"selection\": true,\n        \"encryption\" : true\n    }\n}\n".getBytes(Charset.forName("UTF-8")))));
        uiextensionsManager.setAttachedActivity(this);
        this.pdfViewCtrl.setUIExtensionsManager(uiextensionsManager);
        this.pdfViewCtrl.registerDocEventListener(this.docListener);
        try {
            JSONObject obj = new JSONObject(getIntent().getExtras().getString("path"));
            String path = obj.getString(IHomeModule.FILE_EXTRA).replace("file://", "");
            String annots = obj.getString("annotations");
            Log.i("PATH", path);
            this.mPDFReader = (PDFReader) uiextensionsManager.getPDFReader();
            this.mPDFReader.setOnFinishListener(this.finishListener);
            this.mPDFReader.onCreate(this, this.pdfViewCtrl, null);
            this.mPDFReader.openDocument(path, null);
            Log.i("annotations", annots);
            if (annots != null && annots.length() > 0) {
                this.annotations = new FDFDoc(annots.getBytes(Charset.forName("UTF-8")));
            }
            this.file = File.createTempFile("temp", ".xfdf", getCacheDir());
            setContentView(this.mPDFReader.getContentView());
            this.mPDFReader.onStart(this);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    protected void onStart() {
        super.onStart();
        if(mPDFReader == null)
            return;
        mPDFReader.onStart(this);
    }

    @Override
    protected void onPause() {
        super.onPause();
        if(mPDFReader == null)
            return;
        mPDFReader.onPause(this);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if(mPDFReader == null)
            return;
        mPDFReader.onResume(this);
    }

    @Override
    protected void onStop() {
        super.onStop();
        if(mPDFReader == null)
            return;
        mPDFReader.onStop(this);
    }

    @Override
    protected void onDestroy() {
        if(mPDFReader != null)
            mPDFReader.onDestroy(this);
        super.onDestroy();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if(mPDFReader != null)
            mPDFReader.onActivityResult(this, requestCode, resultCode, data);
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        if(mPDFReader == null)
            return;
        mPDFReader.onConfigurationChanged(this, newConfig);
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (mPDFReader != null && mPDFReader.onKeyDown(this, keyCode, event))
            return true;
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        if (mPDFReader != null && !mPDFReader.onPrepareOptionsMenu(this, menu))
            return false;
        return super.onPrepareOptionsMenu(menu);
    }

    PDFReader.OnFinishListener finishListener = new PDFReader.OnFinishListener() {
        public void onFinish(PDFDoc pdfDoc) {
            ReaderActivity.this.finish();
        }
    };

    PDFViewCtrl.IDocEventListener docListener = new PDFViewCtrl.IDocEventListener() {
        @Override
        public void onDocWillOpen() {
        }

        @Override
        public void onDocOpened(PDFDoc pdfDoc, int errCode) {
            try {
                ReaderActivity.this.annotations.exportAllAnnotsToPDFDoc(pdfDoc);
            } catch (Exception e) {
                e.printStackTrace();
            }
            ReaderActivity.this.pdfViewCtrl.setPageLayoutMode(2);
        }

        @Override
        public void onDocModified(PDFDoc pdfDoc) {

        }

        @Override
        public void onDocWillClose(PDFDoc pdfDoc) {
            try {
                FDFDoc annots = new FDFDoc(1);
                annots.importAllAnnotsFromPDFDoc(pdfDoc);
                Log.i("TMP", ReaderActivity.this.file.getAbsolutePath());
                annots.saveAs(ReaderActivity.this.file.getAbsolutePath());
                Intent intent = new Intent();
                File fl = new File(ReaderActivity.this.file.getAbsolutePath());
                StringBuilder text = new StringBuilder();
                try {
                    BufferedReader br = new BufferedReader(new FileReader(fl));
                    while (true) {
                        String line = br.readLine();
                        if (line == null) {
                            break;
                        }
                        text.append(line);
                        text.append('\n');
                    }
                    br.close();
                } catch (Exception e) {
                }
                Log.i("ANNOTATION", text.toString());
                intent.putExtra("key", text.toString());
                setResult(RESULT_OK, intent);
            } catch (Exception e2) {
                e2.printStackTrace();
            }
        }

        @Override
        public void onDocClosed(PDFDoc pdfDoc, int i) {
            ReaderActivity.this.pdfViewCtrl.unregisterDocEventListener(this);
            ReaderActivity.this.finish();
        }

        @Override
        public void onDocWillSave(PDFDoc pdfDoc) {
        }

        @Override
        public void onDocSaved(PDFDoc pdfDoc, int i) {
            Intent intent = new Intent();

            intent.putExtra("key", "info");

            setResult(RESULT_OK, intent);

            pdfViewCtrl.unregisterDocEventListener(this);

            finish();
        }


    };
}
