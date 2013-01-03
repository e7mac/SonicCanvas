class DistortionEffect implements AudioEffect
{
  void process(float[] samp)
  {
    float[] reversed = new float[samp.length];
    int i = samp.length - 1;
    for (int j = 0; j < reversed.length; i--, j++)
    {
      reversed[j] = (samp[i]+pow(samp[i],3)+pow(samp[i],4))/2;
    }
    // we have to copy the values back into samp for this to work
    arraycopy(reversed, samp);
  }
  
  void process(float[] left, float[] right)
  {
    process(left);
    process(right);
  }
}

class DelayEffect implements AudioEffect
{
  float[] prev = new float[2048];
  void process(float[] samp)
  {
    float[] reversed = new float[samp.length];
    int i = samp.length - 1;
    for (int j = 0; j < reversed.length; i--, j++)
    {
      reversed[j] = samp[j]+0.9*prev[j];
      prev[j] = reversed[j];
    }
    // we have to copy the values back into samp for this to work
    arraycopy(reversed, samp);
  }
  
  void process(float[] left, float[] right)
  {
    process(left);
    process(right);
  }
}



class ReverseEffect implements AudioEffect
{
  void process(float[] samp)
  {
    float[] reversed = new float[samp.length];
    int i = samp.length - 1;
    for (int j = 0; j < reversed.length; i--, j++)
    {
      reversed[j] = samp[i];
    }
    // we have to copy the values back into samp for this to work
    arraycopy(reversed, samp);
  }
  
  void process(float[] left, float[] right)
  {
    process(left);
    process(right);
  }
}

class SinEffect implements AudioEffect
{
  void process(float[] samp)
  {
    for (int i = 0; i < samp.length; i++)
    {
      samp[i] = samp[i]*sin( pi * i / samp.length);
    }
  }
  
  void process(float[] left, float[] right)
  {
    process(left);
    process(right);
  }
}
