<?php
#######################################################################
# Comprobación del acceso HTTP y HTTPS a Packagist, evaluando si la
# resolución se realiza correctamente mediante rutas completas o parciales
# y verificando el comportamiento bajo distintas configuraciones de proxy.
#
# Sintaxis:
#     php ./hProxyTest.php
#
# Parámetros:
#     (ninguno)
#
# Autoría: Marc Bria
# Licencia: GPL
# Última modificación: 03/02/2025
#######################################################################

error_reporting(E_ERROR);                                                                                                                                                                                            
@ini_set('display_errors', 'Off');                                                                                                                                                                                  

echo "Unencrypted HTTP ";                                                                                                                                                                                          
check('http://packagist.org/packages.json', false);                                                                                                                                                                

echo "\nEncrypted HTTPS ";                                                                                                                                                                                         
check('https://packagist.org/packages.json', true);                                                                                                                                                                
echo "\n";                                                                                                                                                                                                         

function check($url, $ssl) {                                                                                                                                                                                       
    foreach (array(false, true) as $fulluri) {                                                                                                                                                                     
        $httpRes = file_get_contents($url, false, createContext($url, $ssl, $fulluri));                                                                                                                            
        echo $fulluri ? 'FULL-' : 'PATH-';                                                                                                                                                                         
        echo strpos($httpRes, 'provider-includes') !== false ? 'OK ' : 'FAIL ';                                                                                                                                    
    }
}

function createContext($url, $ssl, $fulluri)
{
    $options = array('http' => array(
    ));

    if (PHP_SAPI === 'cli' && (!empty($_SERVER['HTTP_PROXY']) || !empty($_SERVER['http_proxy']))) {
        $proxy = parse_url(!empty($_SERVER['http_proxy']) ? $_SERVER['http_proxy'] : $_SERVER['HTTP_PROXY']);
        echo 'HTTP_PROXY ';
    }
    if (!empty($_SERVER['CGI_HTTP_PROXY'])) {
        $proxy = parse_url($_SERVER['CGI_HTTP_PROXY']);
        echo 'CGI_HTTP_PROXY ';
    }
    if (preg_match('{^https://}i', $url) && (!empty($_SERVER['HTTPS_PROXY']) || !empty($_SERVER['https_proxy']))) {
        $proxy = parse_url(!empty($_SERVER['https_proxy']) ? $_SERVER['https_proxy'] : $_SERVER['HTTPS_PROXY']);
        echo 'HTTPS_PROXY ';
    }
    if (!empty($_SERVER['NO_PROXY']) || !empty($_SERVER['no_proxy']) && parse_url($url, PHP_URL_HOST)) {
        echo 'NO_PROXY ';
    }
    if (!empty($proxy)) {
        $proxyURL = isset($proxy['scheme']) ? $proxy['scheme'] . '://' : '';
        $proxyURL .= isset($proxy['host']) ? $proxy['host'] : '';
        if (isset($proxy['port'])) {
            $proxyURL .= ":" . $proxy['port'];
        } elseif ('http://' == substr($proxyURL, 0, 7)) {
            $proxyURL .= ":80";
        } elseif ('https://' == substr($proxyURL, 0, 8)) {
            $proxyURL .= ":443";
        }
        $proxyURL = str_replace(array('http://', 'https://'), array('tcp://', 'ssl://'), $proxyURL);
        if (0 === strpos($proxyURL, 'ssl:') && !extension_loaded('openssl')) {
            throw new \RuntimeException('You must enable the openssl extension to use a proxy over https');
        }
        $options['http']['proxy'] = $proxyURL;
        $options['http']['request_fulluri'] = $fulluri;
        if ('https' === parse_url($url, PHP_URL_SCHEME)) {
            $options['ssl']['SNI_enabled'] = true;
            if (PHP_VERSION_ID < 50600) {
                $options['ssl']['SNI_server_name'] = parse_url($url, PHP_URL_HOST);
            }
        }
        if (isset($proxy['user'])) {
            $auth = urldecode($proxy['user']);
            if (isset($proxy['pass'])) {
                $auth .= ':' . urldecode($proxy['pass']);
            }
            $auth = base64_encode($auth);

            $options['http']['header'] = array("Proxy-Authorization: Basic {$auth}");
        }
    }
    $options['http']['header'][] = 'User-Agent: Proxy-Test';
    uasort($options['http']['header'], function ($el) {
        return preg_match('{^content-type}i', $el) ? 1 : -1;
    });

    return stream_context_create($options);
}
