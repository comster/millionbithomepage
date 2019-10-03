// import Vue from 'vue'

export default {
    replaceTransparent: function(myImageData) {
      for (var i = 0, n = myImageData.length; i <n; i += 4) {
        // var r = myImageData[i],
        //     g = myImageData[i+1],
        //     b = myImageData[i+2],
        //     a = myImageData[i+3]
          
        // Completely transparent
        if(myImageData[i+3] === 0) {
          // Set to solid white
          myImageData[i] = 255;
          myImageData[i+1] = 255;
          myImageData[i+2] = 255;
          myImageData[i+3] = 255;
        }
      }
    },
    clearDraggableImage: function() {
      // Clear the draggable image from the page
      var uploadedImgCanvas = document.getElementById("uploadedImg");
      var uploadedImgCtx = uploadedImgCanvas.getContext("2d");
      uploadedImgCtx.clearRect(0, 0, uploadedImgCanvas.width, uploadedImgCanvas.height);
      uploadedImgCanvas.style.display = 'none';
    }
}