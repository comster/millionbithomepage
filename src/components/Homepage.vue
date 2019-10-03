<template>
  <div class="billboard" id="million-bit-billboard">
    <canvas id="uploadedImg"></canvas>
    <img v-bind:src="s3ImgSrc" usemap="#linkmap" />
    <map name="linkmap">
      <area v-for="link in links" target="_blank" alt="" title="" shape="rect" v-bind:coords="link.c" v-bind:href="link.u">
    </map>
  </div>
</template>

<script>
/*global axios*/
const BASE_S3_BUCKET = process.env.BASE_S3_BUCKET || 'https://millionbithomepagetest.s3-website-us-east-1.amazonaws.com/';
export default {
  name: 'homepage',
  data () {
    return {
      links: [],
      // links: [{c: '0,0,1,1', u: 'http://google.com'}],
      s3Base: BASE_S3_BUCKET,
      s3ImgSrc: BASE_S3_BUCKET+'homepage.jpeg',
      s3LinkMap: BASE_S3_BUCKET+'link_map.json',
      s3PricesJson: BASE_S3_BUCKET+'prices.json',
    };
  },
  created: function () {
    var self = this;
    axios.get(self.s3LinkMap)
      .then(function (response) {
        self.links = response.data;
        axios.get(self.s3PricesJson)
          .then(function (response) {
            window.pricesData = self.prices = response.data;
          })
          .catch(function (error) {
            console.log('Error loading '+self.s3PricesJson, error);
          });
      })
      .catch(function (error) {
        console.log('Error loading '+self.s3LinkMap, error);
      });
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
    width: 1344px;
    height: 832px;
    margin: 33px auto;
  }
  .billboard img {
    box-shadow: 0px 0px 100px #333333;
    image-rendering: pixelated;
  }
</style>
