<template>
  <div id="app">
    <b-navbar toggleable="lg" type="dark" v-bind:variant="variant">
      <b-navbar-brand href="#"><span v-text="logoMoji"></span> <span v-text="title"></span></b-navbar-brand>
  
      <b-navbar-toggle target="nav-collapse"></b-navbar-toggle>
  
      <b-collapse id="nav-collapse" is-nav>
        <b-navbar-nav>
          <b-nav-item href="#" disabled v-text="tagline"></b-nav-item>
        </b-navbar-nav>
  
        <!-- Right aligned nav items -->
        <b-navbar-nav class="ml-auto">
          <b-nav-form>
            <b-button v-bind:variant="variant" v-if="!canBuy && mode == 'classic'" v-on:click="toggleMode">🏠 Homepage</b-button>
            <b-button v-bind:variant="variant" v-if="!canBuy && mode == 'bid'" v-on:click="toggleMode">Classic</b-button>
            <b-button v-b-modal.modal-how-it-works v-bind:variant="variant" v-if="!canBuy">❔ How it works</b-button>
            <b-button v-bind:variant="variant" v-on:click="doUpload" v-if="!canBuy">
              📤 Upload
            </b-button>
            <b-button v-bind:variant="variant" v-if="canBuy" disabled>
              ETH
            </b-button>
            <b-form-input size="md" class="mr-md-2" placeholder="donation amount" v-if="canBuy" id="donation-amount" v-bind:value="ethAmt" style="width: 80px;"></b-form-input>
            <b-form-input size="md" class="mr-md-2" placeholder="http link address" v-if="canBuy && mode == 'bid'" type="url" id="link-url"></b-form-input>
            <b-button variant="warning" v-on:click="doBuy" v-if="canBuy">Donate</b-button>
            <b-button v-bind:variant="variant" v-on:click="cancelBuy" v-if="canBuy">cancel</b-button>
          </b-nav-form>
        </b-navbar-nav>
      </b-collapse>
    </b-navbar>
    <router-view></router-view>
    <b-modal id="modal-how-it-works" title="Own a bit of internet history!" hide-footer size="lg">
      <h3>How it works</h3>
      <p>
        Submit your image and link with an <a href="https://www.ethereum.org/" target="_blank">ETH</a> donation
      </p>
      <p class="text-left">
        <b>Step 0</b>
        Install the <a href="https://metamask.io/" target="_blank">MetaMask</a> extension for your browser.
      </p>
      <p class="text-left">
        <b>Step 1</b>
        Click on the <b-button title="Upload" v-bind:variant="variant" disabled>Upload</b-button> button in the header and select the image you want to submit.
      </p>
      <p class="text-left">
        <b>Step 2</b>
        Drag the image to place it where you want on the canvas.
      </p>
      <p class="text-left">
        <b>Step 3</b>
        Click <b-button title="Donate" variant="warning" disabled>Donate</b-button> in the header.
      </p>
    </b-modal>
    <div id="fine-uploader-manual-trigger" style="display:none;"></div>  
    
    <b-navbar variant="white">
      <b-navbar-brand href="#"><span v-text="logoMoji"></span> <span v-text="title"></span></b-navbar-brand>
      <b-navbar-nav class="ml-auto">
          <b-nav-item href="https://bitcoinhackers.org/@bithomepage" target="_blank" variant="link">Mastadon 🐘</b-nav-item>
          <b-nav-item href="https://twitter.com/BitHomepage" target="_blank" variant="link">Twitter 🐦</b-nav-item>
          <b-nav-item href="https://github.com/comster/millionbithomepage" target="_blank" variant="link">GitHub 🐙</b-nav-item>
          <b-button disabled variant="link">Made with ❤️</b-button>
          <b-button disabled variant="link">© 2019. All rights reserved. Not responsible for the content of external sites or images featured which are © of their respective owners.️</b-button>
        </b-navbar-nav>
    </b-navbar>
  </div>
</template>

<script>

/*global ethers*/
/*global ethereum*/
/*global qq*/
/*global interact*/
/*global pako*/
/*global _*/

import Vue from 'vue'
// import { ToastPlugin } from 'bootstrap-vue'
// console.log(ToastPlugin)
// Vue.use(ToastPlugin)

import Loading from 'vue-loading-overlay';
import 'vue-loading-overlay/dist/vue-loading.css';
Vue.use(Loading);

import utils from './utils'

const DONATION_PIXEL_PRICE = '0.001';
const DONATION_TO_ADDRESS = '0xB811144Cc209be5003c2104E5deE58D44D6DE283';
const BID_TO_ADDRESS = '0xBa0e444a19Dcc00059a598FE001d821795494Ec8';
const ETH_NETWORK = '1'; // '1' is the Ethereum main network ID.
const ETH_GAS_PRICE = process.env.ETH_GAS_PRICE || '0.000000002';
const ETH_GAS_LIMIT = process.env.ETH_GAS_LIMIT || 6000000; // max is around 8000000?

const DO_LOG = process.env.NODE_ENV !== 'production';
function log() {
  if(DO_LOG) {
    console.log.apply(console, arguments);
  }
}

function stringDataForEth(arr, mode, url, bid, r, c) {
  const DATA_ENCODING_VERSION = 1;
  // for(var i in [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]) {
  //   for(var ii in [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]) {
  //     is.push(""+i+","+ii+"#0000ff");
  //   }
  // }
  log('window offset', window.img_offset_x, window.img_offset_y);
  
  if(mode === 'classic') {
    var is = [];
    for(var i in arr) {
      var p = arr[i];
      var x = p['x']+window.img_offset_x;
      var y = p['y']+window.img_offset_y;
      is.push(""+x+","+y+"#"+p['c']);
    }
    return "v"+DATA_ENCODING_VERSION+">"+is.join("|")+">"+encodeURIComponent(url)
  } else {
    
    log('STRING DATA FOR PIXEL DATA', arr, r, c, typeof r, typeof c)
    
    if(typeof r === 'string') {
      r = parseInt(r, 10);
    }
    if(typeof c === 'string') {
      c = parseInt(c, 10);
    }
    // throw new Error("TEST");
    
    let colors = [];
    for(let i in arr) {
      let p = arr[i];
      colors.push(p['hex']);
    }
    let xOffset = ((window.img_offset_x / 16)+c);
    let yOffset = ((window.img_offset_y / 16)+r);
    return "v"+DATA_ENCODING_VERSION+"|"+xOffset+","+yOffset+"|"+colors.join(',')+"|"+bid+"|"+encodeURIComponent(url);
  }
}

function getPriceForPosition(img_offset_x, img_offset_y, canvasWidth, canvasHeight) {
  // window.segmentPrices = [];
  
  var costInWei = ethers.utils.parseEther('0.000'); //.mul((canvasWidth / 16) * (canvasHeight / 16));
  
  // log('getPriceForPosition', img_offset_x, img_offset_y, canvasWidth, canvasHeight)
  // window.segmentPrices.push(costInEth);
  window.segmentPrices = [];
  
  _.times(canvasHeight/16, function(h){
    let cols = [];
    _.times(canvasWidth/16, function(w){
      
      // log('get price for section', h, w)
      let price = "0.000";
      
      // window.pricesData
      // FIND price in data
      let priceDoc = _.find(window.pricesData, { 'x': (img_offset_x/16)+w, 'y': (img_offset_y/16)+h });
      // log(window.pricesData, priceDoc)
      if(priceDoc) {
        price = priceDoc.p;
      }
      
      let sectionPriceInWei = ethers.utils.parseEther(price).add(ethers.utils.parseEther(DONATION_PIXEL_PRICE));
      costInWei = costInWei.add(sectionPriceInWei);
      
      let sectionPrice = ethers.utils.formatEther(sectionPriceInWei);
      
      cols.push(sectionPrice);
    })
    window.segmentPrices.push(cols)
  });
  
  // log('window.segmentPrices', window.segmentPrices)
  var costInEth = ethers.utils.formatEther(costInWei);
  return costInEth;
}

function getHexFromRgb(r, g, b) {
  // pixels_arr[p]["r"].toString(16)+pixels_arr[p]["g"].toString(16)+pixels_arr[p]["b"].toString(16)
  return ("0" + r.toString(16)).slice(-2) + ("0" + g.toString(16)).slice(-2) + ("0" + b.toString(16)).slice(-2);
}

function getPixelsData(myImageData, mode, width, height) {
  var pixels_arr = [];
  var p = 0;
  for(var i in myImageData) {
    if(i % 4 === 0) {
      pixels_arr[p] = {
        "r": myImageData[i]
      };
    } else if(i % 4 === 1) {
      pixels_arr[p]["g"] = myImageData[i];
    } else if(i % 4 === 2) {
      pixels_arr[p]["b"] = myImageData[i];
    } else if(i % 4 === 3) {
      pixels_arr[p]["a"] = myImageData[i];
      // log(pixels_arr[p]["a"])
      pixels_arr[p]["hex"] = getHexFromRgb(pixels_arr[p]["r"], pixels_arr[p]["g"], pixels_arr[p]["b"]);
      // if(p % canvas.width == 0) {
      //   log(pixels_arr[p])
      // }
      p++;
    }
  }
  
  if(mode === 'classic') {
    var pixels_data = [];
  
    var wa = new Array(width);
    var ha = new Array(height);
    for(var hi = 0; hi < ha.length; hi++){
      for(var wi = 0; wi < wa.length; wi++){
        var pixel = pixels_arr.shift();
        // if(wi === 0) {
        //   log(pixel)
        // }
        pixels_data.push({
          x: wi,
          y: hi,
          c: pixel["hex"]
        });
      }
    }
    
    return pixels_data;
  } else {
    
    let rows = []
    var ha = new Array(height / 16);
    var wa = new Array(width / 16);
    for(var hi = 0; hi < ha.length; hi++){ // for each vertical section
      let cols = [];
      for(var wi = 0; wi < wa.length; wi++){ // for each horizontal section
        cols.push([]);
      }
      rows.push(cols);
    }
    
    // rows is multidimension array to hold image data
    
    
    for(let row = 0; row < ha.length; row++){ // for each vertical section
      _.times(16, function(y){
        for(let col = 0; col < wa.length; col++){ // for each horizontal section
          _.times(16, function(x){
            rows[row][col].push(pixels_arr.shift());
          });
        }
      });
    }
    
    return rows;
  }
}

function getScaledContext(origWidth, origHeight, width, height, imgd) {
  
  var newCanvas = document.createElement('canvas');
  newCanvas.width = width;
  newCanvas.height = height;
  newCanvas.style.visibility = 'hidden';
  
  document.body.appendChild(newCanvas);
  
  
  var destCtx = newCanvas.getContext("2d");

  var tmpCanvas = document.createElement('canvas');
  tmpCanvas.width = origWidth;
  tmpCanvas.height = origHeight;
  tmpCanvas.style.visibility = 'hidden';
  document.body.appendChild(tmpCanvas);
  
  tmpCanvas.getContext("2d").putImageData(imgd, 0, 0);
  
  destCtx.drawImage(tmpCanvas, 0, 0, width, height);
  
  return destCtx;
}

function initUploader(self) {
  log('initUploader')
  // let self = this
  window.img_offset_x = 0;
  window.img_offset_y = 0;
  
  if(window.manualUploader) {
    utils.clearDraggableImage();
    window.manualUploader.reset();
    delete window.manualUploader;
  }
  
  if(window.interactable) {
    window.interactable.unset();
    delete window.interactable;
  }
  
  if(self.loader) {
    self.loader.hide();
  }
  
  window.manualUploader = new qq.FineUploader({
      element: document.getElementById('fine-uploader-manual-trigger'),
      template: 'qq-template-manual-trigger',
      callbacks: {
        onStatusChange: function(id, old, newStatus) {
          log("onStatusChange", arguments)
          if(newStatus === 'submitting') {
            self.loader = self.$loading.show({
              // Optional parameters
              // container: this.fullPage ? null : this.$refs.formContainer,
              // canCancel: true,
              // onCancel: this.onCancel,
            });
          } else if (newStatus === 'submitted') {
          } else if (newStatus === 'rejected') {
            this.reset();
            self.loader.hide();
            alert('The selected image is too large.')
          }
        },
        // onSubmitted: function(id) {
        //   log("onSubmitted", self)
        // },
        // onSubmit: function(id) {
        //   log("onSubmit", self)
        // },
        // onCancel: function(id) {
        //   log("CANCELED")
        // },
        // onProgress: function(id) {
        //   log("onProgress")
        // },
        // onValidate: function(id) {
        //   log("onValidate")
        // },
      },
      thumbnails: {
          // placeholders: {
          //     waitingPath: '/source/placeholders/waiting-generic.png',
          //     notAvailablePath: '/source/placeholders/not_available-generic.png'
          // },
        customResizer: !qq.ios() && function(resizeInfo) {
          return new Promise(function(resolve, reject) {
            // log(resizeInfo.sourceCanvas)
            var canvas = resizeInfo.sourceCanvas;
            
            log("Uploaded image", canvas.width, canvas.height);
            
            window.img_offset_x = 0;
            window.img_offset_y = 0;
            
            window.img_width = canvas.width;
            window.img_height = canvas.height;
            
            if(self.mode !== 'classic') {
              // Must be 16 
              if(canvas.width % 16 !== 0 || canvas.height % 16 !== 0) {
                alert('Image dimensions must be in units of 16 pixels. (ie. 16x16, 16x32, 32x32)');
                initUploader(self);
                resolve();
                return;
              }
              
              self.setEthAmt(getPriceForPosition(window.img_offset_x, window.img_offset_y, window.img_width, window.img_height));
            }
            
            var canvasPixels = (canvas.width * canvas.height);
            
            var ctx = resizeInfo.sourceCanvas.getContext('2d');
            // log('canvas size', canvas.width, canvas.height)
            
            var imgd = ctx.getImageData(0, 0, canvas.width, canvas.height);
            var myImageData = imgd.data;
            
            var c=document.getElementById("uploadedImg");
            c.style.display = 'block';
            c.width = canvas.width;
            c.height = canvas.height;
            c.style.width = canvas.width+'px';
            c.style.height = canvas.height+'px';
            var uploadedImgCtx = c.getContext("2d");
            
            // Replace transparent pixels with white
            utils.replaceTransparent(myImageData);
            
            uploadedImgCtx.putImageData(imgd, 0, 0);
            
            // target elements with the "draggable" class
            window.interactable = interact('#uploadedImg')
             .resizable({
                origin: 'parent',
                edges: {
                  top   : false,
                  left  : false,
                  bottom: true,
                  right : true
                },
                modifiers: [
                  interact.modifiers.snap({
                    targets: [
                      (self.mode === 'classic') ? interact.createSnapGrid({ x: 1, y: 1 }) : interact.createSnapGrid({ x: 16, y: 16 })
                    ],
                    relativePoints: [ { x: 0, y: 0 } ]
                  }),
                ],
              })
              .on('resizemove', event => {
                // let { x, y } = event.target.dataset
            
                Object.assign(event.target.style, {
                  width: `${event.rect.width}px`,
                  height: `${event.rect.height}px`,
                  // transform: `translate(${event.deltaRect.left}px, ${event.deltaRect.top}px)`
                });
                window.img_width = event.rect.width;
                window.img_height = event.rect.height;
                
                var destCtx = getScaledContext(c.width, c.height, event.rect.width, event.rect.height, imgd);
                
                let d = destCtx.getImageData(0, 0, event.rect.width, event.rect.height).data
                window.myImageData = d;
                // window.pixels_data = getPixelsData(d, self.mode, event.rect.width, event.rect.height);
                // log(window.pixels_data)
                self.setEthAmt(getPriceForPosition(window.img_offset_x, window.img_offset_y, window.img_width, window.img_height));
                // Object.assign(event.target.dataset, { x, y })
              })
              .draggable({
                origin: 'parent',
                inertia: false, // disable inertial throwing
                // keep the element within the area of it's parent
                // edges: { top: true, left: true },
                modifiers: [
                  interact.modifiers.snap({
                    targets: [
                      (self.mode === 'classic') ? interact.createSnapGrid({ x: 1, y: 1 }) : interact.createSnapGrid({ x: 16, y: 16 })
                    ],
                    relativePoints: [ { x: 0, y: 0 } ]
                  }),
                  interact.modifiers.restrict({
                    restriction: "parent",
                    endOnly: false,
                    elementRect: { top: 0, left: 0, bottom: 1, right: 1 }
                  }),
                ],
                // enable autoScroll
                autoScroll: true,
            
                // call this function on every dragmove event
                onmove: dragMoveListener,
                // call this function on every dragend event
                onend: function (event) {
                  // log(event)
                  var parentPos = document.getElementById('million-bit-billboard').getBoundingClientRect();
                  // log(parentPos.top, parentPos.left)
                  var childrenPos = document.getElementById('uploadedImg').getBoundingClientRect()
                  // log(event.page.x - parentPos.left)
                  // log(childrenPos.left - parentPos.left)
                  window.img_offset_x = Math.floor(childrenPos.left - parentPos.left);
                  window.img_offset_y = Math.floor(childrenPos.top - parentPos.top);
                  // log(event.page.y - parentPos.top)
                  // log(childrenPos.top - parentPos.top)
                  if(self.mode !== 'classic') {
                    // Update price
                    // log('Set price for position', window.img_offset_x, window.img_offset_y, 'size', window.img_width, window.img_height);
                    self.setEthAmt(getPriceForPosition(window.img_offset_x, window.img_offset_y, window.img_width, window.img_height));
                  }
                }
              });
              
            function dragMoveListener (event) {
              var target = event.target,
                  // keep the dragged position in the data-x/data-y attributes
                  x = (parseFloat(target.getAttribute('data-x')) || 0) + event.dx,
                  y = (parseFloat(target.getAttribute('data-y')) || 0) + event.dy;
          
              // translate the element
              // target.style.webkitTransform =
              target.style.transform =
                'translate(' + x + 'px, ' + y + 'px)';
          
              // update the position attributes
              target.setAttribute('data-x', x);
              target.setAttribute('data-y', y);
            }
            
            window.myImageData = myImageData;
            // window.pixels_data = getPixelsData(myImageData, self.mode, canvas.width, canvas.height);
            // log(window.pixels_data)
            // log('pixel data done....');
            self.loader.hide();
            self.canBuy = true;
            
            if(self.mode === 'classic') {
              // Dontation based / classic mode pricing
              var costInWei = ethers.utils.parseEther(DONATION_PIXEL_PRICE).mul(canvasPixels); 
              var costInEth = ethers.utils.formatEther(costInWei);
              self.setEthAmt(costInEth);
            }
            
            resolve();
          });
        },
      },
      autoUpload: false,
      debug: DO_LOG,
      validation: {
        stopOnFirstInvalidFile: true,
        sizeLimit: 200 * 1000
      }
  });
}

function getEncodedEthDataValue(DATA_VALUE_UNENCODED) {
  return ethers.utils.defaultAbiCoder.encode([{"name":"_value","type":"string"}], [DATA_VALUE_UNENCODED]);
}

export default {
  name: 'app',
  data () {
    return {
      logoMoji: '💠',
      title: 'Million Bit Homepage',
      tagline: 'Own a bit of blockchain history!',
      variant: 'primary',
      canBuy: false,
      ethAmt: "0.000",
      mode: this.$route.name == "homepage" ? 'bid' : 'classic' // 'classic' or 'bid'
    }
  },
  methods: {
    setEthAmt: function(amt) {
      this.ethAmt = amt.toString()
    },
    toggleMode: function (event) {
      if(this.mode === 'classic') {
        this.mode = 'bid'
        initUploader(this)
        this.$router.push('/')
      } else {
        this.mode = 'classic'
        initUploader(this)
        this.$router.push('/classic')
      }
    },
    doUpload: function (event) {
      document.querySelector('input[name="qqfile"]').click()
    },
    cancelBuy: function (event) {
      this.resetBuy();
    },
    resetBuy: function() {
      this.canBuy = false;
      initUploader(this);
    },
    doBuy: function (event) {
      var self = this;
      // Load pixel data
      window.pixels_data = getPixelsData(window.myImageData, self.mode, window.img_width, window.img_height);
      log(window.pixels_data);
      log('pixel data done....');
      
      // Detect whether the current browser is ethereum-compatible,
      // and handle the case where it isn't:
      if (typeof window.ethereum === 'undefined') {
        alert('You need a Dapp browser like MetaMask to send transactions.');
      } else {
      
        // In the case the user has MetaMask installed, you can easily
        // ask them to sign in and reveal their accounts:
        ethereum.enable()
      
        // Remember to handle the case they reject the request:
        .catch(function (reason) {
          if (reason === 'User rejected provider access') {
            // The user didn't want to sign in!
          } else {
            // This shouldn't happen, so you might want to log this...
            alert('There was an issue signing you in.')
          }
        })
      
        // In the case they approve the log-in request, you'll receive their accounts:
        .then(function (accounts) {
          // You also should verify the user is on the correct network:
          if (ethereum.networkVersion !== ETH_NETWORK) {
            alert('This application requires the main network, please switch it in your MetaMask UI.')
            // We plan to provide an API to make this request in the near future.
            // https://github.com/MetaMask/metamask-extension/issues/3663
          }
      
          // Once you have a reference to user accounts,
          // you can suggest transactions and signatures:
          const account = accounts[0]
          sendEtherFrom(account, function (err, transaction) {
            if (err) {
              return alert(`The transaction failed.`)
            }
      
            alert('Your transaction has been received!');
          })
        })
      }
      
      function sendEtherFrom (account, callback) {
      
        // let data_encoded = '0x';
        // var is = [];
        // // for(var i in [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]) {
        // //   for(var ii in [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]) {
        // //     is.push(""+i+","+ii+"#0000ff");
        // //   }
        // // }
        
        // for(var i in window.pixels_data) {
        //   var p = window.pixels_data[i];
        //   var x = p['x']+window.img_offset_x;
        //   var y = p['y']+window.img_offset_y;
        //   is.push(""+x+","+y+"#"+p['c']);
        // }
        
        // var DATA_VALUE_UNENCODED = is.join("|")+">"+encodeURIComponent('http://google.com/?q=ethereum+test');
        // var DATA_VALUE_UNENCODED = stringDataForEth(window.pixels_data, 'http://google.com/?q=ethereum+test');
        let donation_amount_el = document.getElementById('donation-amount');
        let link_url_el = document.getElementById('link-url');
        
        var donation_amount = donation_amount_el.value;
        var link_url = link_url_el.value;
        
        log('donation amount', donation_amount)
        log('link url', link_url)
        log('MODE', self.mode)
        
        if(self.mode !== 'classic' && link_url.indexOf('http') !== 0) {
          alert('Please provide a valid link URL before purchasing.');
          link_url_el.focus();
          return false;
        }
        
        var pixels_data_str;
        if(self.mode !== 'classic') {
          
          let pixels_data_strs = [];
          // for each bids
          // pixels_data_strs.push(stringDataForEth(window.pixels_data, self.mode, link_url, bid));
          for(var r in window.segmentPrices) {
            for(var c in window.segmentPrices[r]) {
              pixels_data_strs.push(stringDataForEth(window.pixels_data[r][c], self.mode, link_url, window.segmentPrices[r][c], r, c));
            }   
          }
          
          log('pixels_data_strs', pixels_data_strs)
          
          pixels_data_str = pixels_data_strs.join('\n');
        } else {
          pixels_data_str = stringDataForEth(window.pixels_data, self.mode, link_url);
        }
        
        var pixels_data_gzip_str = pako.deflate(pixels_data_str, { to: 'string' });
        
        // log('pixels_data_str: '+pixels_data_str);
        log('pixels_data_str length: '+pixels_data_str.length);
        log('pixels_data_gzip_str length: '+pixels_data_gzip_str.length);
        log('compression ratio: '+(pixels_data_str.length/pixels_data_gzip_str.length));
        
        let gasLimit = web3.toHex(ETH_GAS_LIMIT);
        let gasPrice = ethers.utils.parseEther(ETH_GAS_PRICE)._hex;
        
        if(ethers.utils.parseEther(donation_amount).lt(ethers.utils.parseEther(self.ethAmt))) {
          alert("The minimum eth donation for this image is "+self.ethAmt);
          donation_amount_el.focus();
          return false;
        }
        
        let trxAmount = ethers.utils.parseEther(donation_amount)._hex;
        
        const method = 'eth_sendTransaction';
        const parameters = [{
          // gasPrice: '0x09184e72a000', // customizable by user during MetaMask confirmation.
          // gasLimit: '0x2710',  // customizable by user during MetaMask confirmation.
          gasPrice: gasPrice,
          gas: gasLimit,
          from: account,
          to: self.mode === 'classic' ? DONATION_TO_ADDRESS : BID_TO_ADDRESS,
          value: trxAmount,
          data: getEncodedEthDataValue(pixels_data_gzip_str),
        }];
        const from = account;
      
        const payload = {
          method: method,
          params: parameters,
          from: from,
        };
      
        // Methods that require user authorization like this one will prompt a user interaction.
        // Other methods (like reading from the blockchain) may not.
        ethereum.sendAsync(payload, function (err, response) {
          const rejected = 'User denied transaction signature.';
          if (response.error && response.error.message.includes(rejected)) {
            return alert(`The transaction was canceled.`);
          }
      
          if (err) {
            log(err);
            return alert('There was an error, please try again.');
          }
      
          if (response.result) {
            // If there is a response.result, the call was successful.
            // In the case of this method, it is a transaction hash.
            const txHash = response.result;
            alert('Your transaction has been sent!');
            
            self.resetBuy();
      
            // You can poll the blockchain to see when this transaction has been mined:
            pollForCompletion(txHash, callback);
          }
        })
      }
      
      function pollForCompletion (txHash, callback) {
        let calledBack = false;
      
        // Normal ethereum blocks are approximately every 15 seconds.
        // Here we'll poll every 2 seconds.
        const checkInterval = setInterval(function () {
      
          const notYet = 'response has no error or result';
          
          ethereum.sendAsync({
            method: 'eth_getTransactionByHash',
            params: [ txHash ],
          }, function (err, response) {
            if (calledBack) return;
            if (err || response.error) {
              if (err.message.includes(notYet)) {
                return 'transaction is not yet mined';
              }
              callback(err || response.error);
            }
            // We have successfully verified the mined transaction.
            // Mind you, we should do this server side, with our own blockchain connection.
            // Client side we are trusting the user's connection to the blockchain.
            const transaction = response.result;
            clearInterval(checkInterval);
            calledBack = true;
            callback(null, transaction);
          });
        }, 2000);
      }
    }
  },
  mounted() {
    initUploader(this)
  }
}
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  background: #bebebe;
  margin-top: 0px;
}
</style>
