package com.example.ffsim;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.JavascriptInterface;
import android.content.Intent;
import android.net.Uri;
import android.graphics.Color;

public class MainActivity extends Activity {
    private WebView web;
    public class AndroidBridge {
        @JavascriptInterface public void openUrl(String url) {
            try { startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse(url))); }
            catch (Exception ignored) {}
        }
    }
    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        web=new WebView(this);
        web.setBackgroundColor(Color.rgb(7,9,14));
        web.setWebViewClient(new WebViewClient());
        WebSettings s=web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setBuiltInZoomControls(false);
        s.setDisplayZoomControls(false);
        web.addJavascriptInterface(new AndroidBridge(),"AndroidBridge");
        web.loadUrl("file:///android_asset/index.html");
        setContentView(web);
    }
}
