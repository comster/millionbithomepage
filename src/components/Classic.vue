<template>
  <div class="billboard" id="million-bit-billboard">
    <canvas id="uploadedImg"></canvas>
    <img v-bind:src="s3ImgSrc" />
  </div>
</template>

<script>
const BASE_S3_BUCKET = process.env.BASE_S3_BUCKET || 'https://millionbithomepagetest.s3-website-us-east-1.amazonaws.com/'
export default {
  name: 'classic',
  data () {
    return {
      s3Base: BASE_S3_BUCKET,
      s3ImgSrc: BASE_S3_BUCKET+'classic.jpeg',
    }
  },
  created: function () {
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
  #uploadedImg {
    position: absolute;
    display: none;
  }
  .billboard {
    width: 1000px;
    height: 1000px;
    margin: 0 auto;
  }
  .billboard img {
    box-shadow: 0px 0px 100px #333333;
    image-rendering: pixelated;
  }
</style>
